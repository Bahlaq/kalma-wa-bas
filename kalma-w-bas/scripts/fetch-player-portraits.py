#!/usr/bin/env python3
"""Fetch player photographs with verified identities and explicit provenance.

Wikimedia thumbnails retain verified free licenses. Researched profile portraits
are explicitly labeled with retained rights when no free reuse license is stated.
All image bytes remain unmodified. Source, creator and license information are
retained in data/photo-catalog.json and the browser module.
All requests use read-only public MediaWiki/Wikidata endpoints.
"""
from __future__ import annotations
import argparse, concurrent.futures, hashlib, html, io, json, os, re, sys, time, urllib.parse, urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'data'
DEST=ROOT/'dist/assets/players'
UA='KalmaFootballGame/1.0 (player-portrait-research; educational photo attribution)'
THREADS=3
PREVIOUS_CATALOG={}

def load(name, default=None):
    p=DATA/name
    return json.loads(p.read_text()) if p.exists() else default

def save(name, value):
    (DATA/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')

def get(url, *, binary=False):
    for attempt in range(6):
        try:
            req=urllib.request.Request(url,headers={'User-Agent':UA,'Accept':'*/*' if binary else 'application/json'})
            with urllib.request.urlopen(req,timeout=40) as r:
                b=r.read()
                return (b,r.headers.get('Content-Type','')) if binary else json.loads(b)
        except Exception as exc:
            if attempt==5: raise
            delay=min(30, 3 * (attempt+1)) if getattr(exc, "code", None) == 429 else 1.5 * (attempt+1)
            print("Retry", urllib.parse.urlparse(url).netloc, type(exc).__name__, getattr(exc,"code",None), "in", delay, "seconds", flush=True)
            time.sleep(delay)

def api(domain, **params):
    return get(f'https://{domain}/w/api.php?'+urllib.parse.urlencode({'action':'query','format':'json',**params}))

def batched(seq,n=25):
    return [seq[i:i+n] for i in range(0,len(seq),n)]

def threaded(fn, seq, workers=THREADS):
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        yield from pool.map(fn,seq)

def wiki_batch(spec):
    lang,titles=spec
    d=api(f'{lang}.wikipedia.org',prop='pageimages|pageprops|langlinks',piprop='name|original|thumbnail',pithumbsize=320,redirects=1,lllang='en',lllimit=500,titles='|'.join(titles))
    q=d.get('query',{})
    alias={x['from']:x['to'] for k in ['normalized','redirects'] for x in q.get(k,[])}
    pages={x['title']:x for x in q.get('pages',{}).values()}
    result={}
    for title in titles:
        resolved=title
        for _ in range(8):
            if resolved not in alias: break
            resolved=alias[resolved]
        p=pages.get(resolved,{'title':resolved,'missing':True})
        result[title]={**p,'wikiLang':lang,'wikiUrl':f'https://{lang}.wikipedia.org/wiki/'+urllib.parse.quote(p['title'].replace(' ','_'))}
    return result

def map_wiki(players):
    cache=load('photo-wikipedia.json',{})
    overrides=load('photo-overrides.json',{})
    reqs={}
    for p in players:
        o=overrides.get(p['id'],{})
        lang=o.get('lang','ar'); title=o.get('title',p['name'])
        key=lang+':'+title
        if key not in cache: reqs.setdefault(lang,[]).append(title)
    specs=[(lang,b) for lang,titles in reqs.items() for b in batched(list(dict.fromkeys(titles)),25)]
    for spec,result in zip(specs,threaded(wiki_batch,specs)):
        cache.update({spec[0]+':'+t:p for t,p in result.items()})
        save('photo-wikipedia.json',cache)
        print('Wiki batch:',spec[0],len(result),flush=True)
    mapped={}
    for p in players:
        o=overrides.get(p['id'],{})
        lang=o.get('lang','ar');title=o.get('title',p['name'])
        w=cache[lang+':'+title]
        mapped[p['id']]={**p,'article':w,'candidateFile':o.get('file',w.get('pageimage'))}
    save('photo-map.json',mapped)
    missing=[{'id':k,'name':p['name'],'wikiTitle':p['article']['title'],'en':p['article'].get('langlinks',[]),'reason':'disambiguation' if 'disambiguation' in p['article'].get('pageprops',{}) else 'missing page or image'} for k,p in mapped.items() if 'missing' in p['article'] or 'disambiguation' in p['article'].get('pageprops',{}) or not p['candidateFile']]
    save('photo-missing.json',missing)
    print('Mapped:',len(mapped),'candidate files:',sum(bool(p['candidateFile']) for p in mapped.values()),'missing/ambiguous:',len(missing),flush=True)
    print(json.dumps(missing,ensure_ascii=False,indent=2),flush=True)
    return mapped

def entity_batch(ids):
    u='https://www.wikidata.org/w/api.php?'+urllib.parse.urlencode(dict(action='wbgetentities',format='json',ids='|'.join(ids),props='labels|descriptions|claims|sitelinks',languages='en|ar',sitefilter='enwiki|arwiki'))
    raw=get(u).get('entities',{})
    props={'P31','P106','P18','P373','P569','P27','P2574','P2446'}
    return {key:{**{k:q[k] for k in ['id','lastrevid','modified','labels','descriptions','sitelinks'] if k in q},'claims':{k:[{s:st[s] for s in ['mainsnak','rank'] if s in st} for st in v] for k,v in q.get('claims',{}).items() if k in props}} for key,q in raw.items()}

def entities(mapped):
    cache=load('photo-entities.json',{})
    ids=list(dict.fromkeys(p['article'].get('pageprops',{}).get('wikibase_item') for p in mapped.values()))
    ids=[i for i in ids if i and i not in cache]
    for d in threaded(entity_batch,batched(ids,40)):
        cache.update(d);save('photo-entities.json',cache)
        print('Entity batch:',len(d),flush=True)
    return cache

def plain(value):
    return html.unescape(re.sub(r'<[^>]*>',' ',value or '')).strip()

def metadata_batch(files):
    d=api('commons.wikimedia.org',prop='imageinfo',iiprop='url|size|mime|extmetadata',iiurlwidth=320,redirects=1,titles='|'.join('File:'+f for f in files))
    q=d.get('query',{})
    alias={x['from']:x['to'] for k in ['normalized','redirects'] for x in q.get(k,[])}
    pages={x['title']:x for x in q.get('pages',{}).values()}
    out={}
    for f in files:
        t='File:'+f
        for _ in range(8):
            if t not in alias:break
            t=alias[t]
        out[f]=pages.get(t,{'title':t,'missing':True})
    return out

def metadata(mapped):
    cache=load('photo-metadata.json',{})
    files=list(dict.fromkeys(p['candidateFile'] for p in mapped.values() if p['candidateFile']))
    pending=[f for f in files if f not in cache]
    for result in threaded(metadata_batch,batched(pending,20)):
        cache.update(result);save('photo-metadata.json',cache)
        print('Metadata batch:',len(result),flush=True)
    return cache

def permitted(info):
    e=info.get('extmetadata',{})
    short=plain(e.get('LicenseShortName',{}).get('value',''))
    usage=plain(e.get('UsageTerms',{}).get('value',''))
    license_key=plain(e.get('License',{}).get('value',''))
    allowed=any(x in (short+' '+usage+' '+license_key).lower() for x in ['cc by','cc-by','cc0','public domain','pd-','free art license','gfdl','attribution'])
    forbidden=any(x in (short+' '+usage+' '+license_key).lower() for x in ['non-free','fair use','noncommercial','non-commercial','no derivatives','by-nc','by-nd'])
    return allowed and not forbidden

def download_one(entry):
    ident,p,meta=entry
    if p.get('externalPhoto'):
        return download_external(ident,p,p['externalPhoto'])
    file=p['candidateFile']; page=meta.get(file,{})
    info=(page.get('imageinfo') or [{}])[0]
    if not permitted(info):
        return ident,None,{'id':ident,'name':p['name'],'reason':'no verified freely reusable Commons image','file':file,'metadata':info.get('extmetadata',{})}
    url=info.get('thumburl') or info.get('url')
    if not url:
        return ident,None,{'id':ident,'name':p['name'],'reason':'missing image download URL','file':file}
    url=url.split('?')[0]
    mime=info.get('mime','image/jpeg')
    ext={'image/jpeg':'.jpg','image/png':'.png','image/webp':'.webp','image/gif':'.gif'}.get(mime)
    if not ext:
        return ident,None,{'id':ident,'name':p['name'],'reason':'unsupported image type','file':file,'mime':mime}
    path=DEST/(ident+ext)
    e=info['extmetadata']
    author=plain(e.get('Artist',{}).get('value','')) or plain(e.get('Attribution',{}).get('value',''))
    if not author:
        author='Author credited on Wikimedia Commons source page'
    record={'src':'/assets/players/'+path.name,'source':info['descriptionurl'],'author':re.sub(r'\s+',' ',author),'license':plain(e.get('LicenseShortName',{}).get('value','')),'licenseUrl':plain(e.get('LicenseUrl',{}).get('value','')) or info['descriptionurl'],'wiki':p['article']['wikiUrl'],'name':p['name'],'file':file,'title':file.replace('_',' '),'downloadUrl':url,'wikidata':p['article'].get('pageprops',{}).get('wikibase_item'),'attribution':plain(e.get('Attribution',{}).get('value','')),'copyrighted':plain(e.get('Copyrighted',{}).get('value','')),'restrictions':plain(e.get('Restrictions',{}).get('value','')),'imageDescription':plain(e.get('ImageDescription',{}).get('value','')),'originalWidth':info.get('width'),'originalHeight':info.get('height'),'sourceKind':'Wikimedia Commons','reuseLicenseVerified':True}
    try:
        prior=PREVIOUS_CATALOG.get(ident,{})
        if path.exists() and prior and prior.get('downloadUrl') != url:
            path.unlink()
        if not path.exists():
            data,content_type=get(url,binary=True)
            if not content_type.startswith('image/') or len(data)<500:
                raise RuntimeError('Unexpected image response '+content_type)
            path.write_bytes(data)
        from PIL import Image
        with Image.open(path) as im:
            record['width'],record['height']=im.size
            im.verify()
        record['bytes']=path.stat().st_size
        record['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
        return ident,record,None
    except Exception as exc:
        return ident,None,{'id':ident,'name':p['name'],'reason':'download failed: '+str(exc),'file':file,'url':url}

def download_external(ident,p,source):
    """Keep source photographs byte-for-byte, without claiming a free license."""
    from PIL import Image
    url=source['downloadUrl']
    try:
        prior=PREVIOUS_CATALOG.get(ident,{})
        priorpath=ROOT/'dist'/prior.get('src','').lstrip('/')
        if prior.get('downloadUrl')==url and priorpath.is_file():
            data=priorpath.read_bytes()
        else:
            try:
                data,content_type=get(url,binary=True)
            except Exception:
                if not source.get('fallbackUrl'):raise
                url=source['fallbackUrl']
                data,content_type=get(url,binary=True)
            if not content_type.startswith('image/') or len(data)<500:
                raise RuntimeError('Unexpected image response '+content_type)
        with Image.open(io.BytesIO(data)) as im:
            width,height=im.size
            ext={'JPEG':'.jpg','PNG':'.png','WEBP':'.webp'}.get(im.format)
            im.verify()
        if not ext:raise RuntimeError('Unsupported external photograph format')
        path=DEST/(ident+ext)
        path.write_bytes(data)
        record={**source,'src':'/assets/players/'+path.name,'downloadUrl':url,'name':p['name'],'width':width,'height':height,'bytes':len(data),'wiki':source.get('wiki') or (p['article']['wikiUrl'] if 'missing' not in p['article'] else ''),'wikidata':source.get('wikidata') or p['article'].get('pageprops',{}).get('wikibase_item'),'reuseLicenseVerified':False,'sha256':hashlib.sha256(data).hexdigest()}
        return ident,record,None
    except Exception as exc:
        return ident,None,{'id':ident,'name':p['name'],'reason':'external download failed: '+str(exc),'url':url}

def download(mapped,meta):
    global PREVIOUS_CATALOG
    DEST.mkdir(parents=True,exist_ok=True)
    catalog=load('photo-catalog.json',{})
    PREVIOUS_CATALOG=dict(catalog)
    external=load('photo-external.json',{})
    failures=[]
    safe={k:p for k,p in mapped.items() if p['candidateFile'] and 'disambiguation' not in p['article'].get('pageprops',{}) and 'missing' not in p['article']}
    safe.update({k:{**mapped[k],'externalPhoto':record} for k,record in external.items()})
    for ident,record,error in threaded(download_one,[(k,p,meta) for k,p in safe.items()],workers=8):
        if record:catalog[ident]=record
        else:failures.append(error);catalog.pop(ident,None)
        if len(catalog)%25==0:print('Downloaded/catalogued:',len(catalog),flush=True);save('photo-catalog.json',catalog)
    for ident,p in mapped.items():
        if ident not in safe:
            failures.append({'id':ident,'name':p['name'],'reason':'missing image or ambiguous identity','file':p['candidateFile']})
            catalog.pop(ident,None)
    save('photo-catalog.json',catalog)
    save('photo-missing.json',failures)
    used={Path(r['src']).name for r in catalog.values()}
    for file in DEST.glob('p[0-9][0-9][0-9].*'):
        if file.name not in used:file.unlink()
    public={k:{key:r.get(key,'') for key in ['src','source','author','license','licenseUrl','wiki','attribution','title']} for k,r in sorted(catalog.items())}
    (ROOT/'dist/player-photos.mjs').write_text('// Local player photographs; provenance and actual rights labels retained.\nexport const PLAYER_PHOTOS = '+json.dumps(public,ensure_ascii=False,indent=2)+';\n')
    print('Final:',len(catalog),'photos;',len(failures),'missing;',sum(p['bytes'] for p in catalog.values())/1e6,'MB',flush=True)
    print(json.dumps(failures,ensure_ascii=False,indent=2),flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--stage',choices=['map','entities','metadata','download','all'],default='all');a=parser.parse_args()
    players=load('players-input.json')
    mapped=map_wiki(players) if a.stage in ['map','all'] else load('photo-map.json')
    if a.stage in ['entities','all']:entities(mapped)
    meta=metadata(mapped) if a.stage in ['metadata','all'] else load('photo-metadata.json',{})
    if a.stage in ['download','all']:download(mapped,meta)

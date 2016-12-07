input metauml;
%input boxes;
verbatimtex
\documentclass[12pt]{article}
\usepackage[ngerman]{babel}
\usepackage[utf8]{inputenc}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsthm}

\begin{document}
etex

vardef stack(text elms)(text equ)=
  save obj;
  PictureStack.obj(elms)("vleft");
  equ;
  drawObject(obj);
enddef;
beginfig(1);

  Actor.anwender("Anwender");
  Component.client("Client")();
  Component.browser("Browser")(client);
  Component.es("ElasticSearch")();
  Component.fs("Dateisystem")();
  Component.api("API")();
  Component.proxy("Proxy")();
  Component.fileServer("FileServer")();
  Component.irma("Irma")(api, proxy, fileServer);
  Component.gepris("GEPRIS")();

  leftToRight(130)(api, proxy,fileServer);
  topToBottom(100)(browser, irma);
  leftToRight(130)(anwender,browser);
  topToBottom(100)(proxy, gepris);
  topToBottom(100)(api, es);
  topToBottom(100)(fileServer, fs);

  drawObjects(anwender,browser,irma, es, fs, gepris);


  link(association)(anwender.e -- browser.w);
  stack(
    btex 1: öffnet GEPRIS $\blacktriangleright$ etex,
    btex 2: sucht "Biene" $\blacktriangleright$ etex
  )(obj.s=.5[anwender.e,browser.w]);
  link(association)(api.s -- es.n);
  stack(
    btex 2.1.1: GET (JSON query) $\blacktriangledown$ etex,
    btex 2.1.1.1: (Ergebnisse, roh, JSON) $\blacktriangle$ etex
  )(obj.w=.5[api.s,es.n]);
  link(association)(proxy.s -- gepris.n);
  stack(
    btex 1.1.1: GET /index.html $\blacktriangledown$ etex,
    btex 1.1.1.1: (original HTML) $\blacktriangle$ etex
  )(obj.w=.5[proxy.s,gepris.n]);

  link(association)(fileServer.s -- fs.n);
  stack(
    btex 1.2.1: liest Datei $\blacktriangledown$ etex,
    btex 1.2.1.1: (js code) $\blacktriangle$ etex
  )(obj.w=.5[fileServer.s,fs.n]);
  clink(association)(browser, irma);
  stack(
    btex 1.1: GET /index.html $\blacktriangledown$ etex,
    btex 1.1.2: (augmentiertes HTML) $\blacktriangle$ etex,
    btex 1.2: GET /client.js $\blacktriangledown$ etex,
    btex 1.2.2: (js code) $\blacktriangle$ etex
  )(obj.w=.5[browser.s,irma.n]);
  link(association)(pathStepY(.5[client.sw, client.s], api.n, -50));
  stack(
    btex 2.1: GET /search?q=biene $\blacktriangledown$ etex,
    btex 2.1.2: (Ergebnisse, JSON) $\blacktriangle$ etex
  )(obj.w=api.n+(0,50));
  link(association)(pathStepX(.5[browser.ne, browser.e], client.e, 60));
  stack(
    btex 1.2.2.1: erzeugt $\blacktriangledown$ etex,
    btex 1.2.2.1.1: (modifiziert DOM) $\blacktriangle$ etex,
    btex 2.1.2.1: (modifiziert DOM) $\blacktriangle$ etex
  )(obj.w = .5[.5[browser.ne,client.e], browser.e] + (60,0));


endfig;
end;

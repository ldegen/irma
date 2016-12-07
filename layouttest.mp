
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

  Component.a("A")();
  Component.b("B")();
  topToBottom(200)(a,b);
  stack(
      btex 1.1: GET /index.html $\blacktriangledown$\\ etex,
      btex 1.1.2: (augmented HTML) $\blacktriangle$\\ etex,
      btex 1.2: GET /client.js $\blacktriangledown$\\ etex,
      btex 1.2.2: (js code) $\blacktriangle$\\ etex
  )(obj.w=.5[a.s,b.n]);
  drawObjects(a,b);
  link(association)(a.s -- b.n);
endfig;
end;

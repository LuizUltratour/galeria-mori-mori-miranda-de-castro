# Modern Galeria — Mori Mori Miranda de Castro

Galeria de imagens/plantas/vídeos para injeção via script no 3DVista, hospedada no AWS S3.

**Projeto:** Mori Mori — Miranda de Castro
**Tema:** verde imersivo (`#325825` / `#EAFFF7`)

---

## URLs de produção

| Arquivo | URL |
|---------|-----|
| Galeria | `https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/mori-mori/galeria-miranda-de-castro/index.html` |
| Vídeos  | `https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/mori-mori/galeria-miranda-de-castro/video-gallery.html` |
| Script  | `https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/mori-mori/galeria-miranda-de-castro/inject.js` |

**S3 path:** `s3://skylineip/Tour Virtual/mori-mori/galeria-miranda-de-castro/`

---

## Estrutura de arquivos

```
galeria/  (Mori Mori / Miranda de Castro)
├── index.html              ← galeria de imagens + plantas (auto-suficiente)
├── video-gallery.html      ← galeria de vídeos (vídeo 3D único)
├── diferenciais.html       ← ficha de diferenciais (scroll)
├── inject.js               ← loader leve para injeção no 3DVista
├── deploy.ps1              ← deploy para o S3 (Windows; sync)
├── generate_thumbs.ps1     ← gerador de thumbnails (Windows/GDI+, sem deps)
├── generate_thumbs.py      ← gerador alternativo (Python + Pillow)
└── assets/
    ├── IMAGENS/              ← renders: fachadas e áreas comuns (Fachada *.png, Scene NN.png)
    ├── PLANTAS/              ← apartamento decorado, plantas humanizadas e implantação
    ├── VIDEO/                ← vídeo 3D .mp4 (gitignored; direto no S3)
    ├── bg.png                ← imagem de fundo da galeria
    ├── close-*, voltar-*, proximo-*.png ← botões (normal/hover), exibidos em 45×45 px
    ├── large/                ← versões ~2560 px (lightbox), geradas
    ├── BOOK-PRINT.pdf        ← book de referência (gitignored, não sobe ao S3)
    └── thumbs/               ← gerado automaticamente (espelha a árvore, .jpg)
```

> **Pastas = categorias.** Os nomes das pastas em `assets/` definem as categorias/subcategorias da galeria. O S3 é case-sensitive: os caminhos em `index.html` devem ter exatamente o mesmo case das pastas/arquivos (ex.: `assets/IMAGENS/...`). Espaços são aceitos (o navegador codifica a URL).

---

## Categorias da galeria

### Modo `imagens`

| Categoria | Label | Pasta | Qtde |
|-----------|-------|-------|------|
| `fachadas`     | Fachadas | `assets/IMAGENS/` | 7 |
| `areas-comuns` | Áreas Comuns | `assets/IMAGENS/` | 28 |
| `apartamento`  | Apartamento Decorado | `assets/PLANTAS/` | 8 (sala de estar/jantar, cozinha, quartos infantis, suítes, banheiro) |

### Modo `plantas`

| Tipologia | Label | Pasta | Formato |
|-----------|-------|-------|---------|
| `pl-apartamentos` | Apartamento | `assets/PLANTAS/` | Planta Humanizada 01 e 02 |
| `pl-implantacao`  | Implantação | `assets/PLANTAS/` | Implantação (com e sem fundo) |

> No modo `all` (padrão) as plantas aparecem como categoria "Plantas" com os dois sub-filtros acima.

### Vídeos

`video-gallery.html` toca um único vídeo 3D (`assets/VIDEO/VÍDEO 3D - MIRANDA DE CASTRO - COM FRASES.mp4`, ~320 MB, vertical 2160×3884). O arquivo é grande demais para o GitHub: fica só no S3 (`assets/VIDEO/` está no .gitignore).

---

## Cards de plantas com abas (`cobertura-plan`)

Plantas que são **níveis de um mesmo conjunto** podem ser agrupadas num único card com abas
que alternam (e sobrepõem) as variantes. Quando há **exatamente 2 pisos**, aparece também
o botão "Ver ambas" (comparação lado a lado); com mais pisos, só as abas. Nenhum item do
projeto atual usa esse formato — todas as plantas são cards individuais —
mas o suporte permanece no motor da galeria para uso futuro:

```js
{ type:'cobertura-plan', category:'plantas', subCategory:'pl-apartamentos',
  title:'Pavimentos — Apartamentos', subtitle:'Apartamentos', floors:[
    { label:'Térreo',       src:'assets/plantas/terreo.jpg',       thumb:'assets/thumbs/plantas/terreo.jpg' },
    { label:'Tipo',         src:'assets/plantas/tipo.jpg',         thumb:'assets/thumbs/plantas/tipo.jpg' },
]},
```

---

## Thumbnails

Todo `src` da grade usa um `thumb` leve (**900 px, JPEG q82**, achatado sobre branco).
Geração **sem dependências** no Windows via GDI+:

```powershell
# Gera apenas os que faltam / desatualizados
./generate_thumbs.ps1

# Regenera todos
./generate_thumbs.ps1 -Force
```

O script espelha `assets/` em `assets/thumbs/` (sempre `.jpg`, mesmo caminho/case),
ignora `thumbs/`, `videos/` e o PDF. Também gera `large/` (~2560 px, q88) usado no lightbox.

> Alternativa multiplataforma: `python generate_thumbs.py` (requer Python + Pillow).

---

## Deploy AWS S3

> **Windows:** use o script pronto `./deploy.ps1` (faz o sync completo + `cache-control` no HTML/JS).
> Requer **AWS CLI** instalado e credenciais configuradas (`aws configure`) uma única vez.

### Sync completo

```bash
aws s3 sync . "s3://skylineip/Tour Virtual/mori-mori/galeria-miranda-de-castro/" \
  --exclude ".git/*" --exclude ".claude/*" --exclude "*.py" \
  --exclude "README.md" --exclude ".gitattributes" --exclude "*.md" \
  --exclude "deploy.ps1" --exclude "*.pdf" \
  --delete
```

### Atualizar só index.html e inject.js

```bash
aws s3 cp index.html "s3://skylineip/Tour Virtual/mori-mori/galeria-miranda-de-castro/index.html" \
  --cache-control "no-cache,no-store,must-revalidate"

aws s3 cp inject.js "s3://skylineip/Tour Virtual/mori-mori/galeria-miranda-de-castro/inject.js" \
  --cache-control "no-cache,no-store,must-revalidate"
```

> **`--cache-control "no-cache,no-store,must-revalidate"`** — essencial para garantir que o browser nunca sirva uma versão cacheada do script ou da galeria.

---

## Integração 3DVista

### Passo 1 — Loader (colocar no JavaScript global do projeto)

```js
(function(){
  var s = document.createElement('script');
  s.src = 'https://skylineip.s3.sa-east-1.amazonaws.com/Tour+Virtual/mori-mori/galeria-miranda-de-castro/inject.js?v=' + Date.now();
  document.head.appendChild(s);
})();
```

> **`?v=` + `Date.now()`** — cache-busting: força o browser a baixar sempre a versão mais recente do script, evitando que o 3DVista sirva uma versão antiga em cache.

### Passo 2 — Acionar nos hotspots/botões

```js
// Abre galeria de imagens
GaleriaImagens(1);

// Fecha galeria de imagens
GaleriaImagens(0);

// Abre galeria de plantas
GaleriaPlantas(1);

// Fecha galeria de plantas
GaleriaPlantas(0);

// Abre galeria de vídeos (vídeo 3D — video-gallery.html)
AbrirGaleriaVideos(1);

// Fecha galeria de vídeos
AbrirGaleriaVideos(0);

// Abre a ficha de diferenciais
AbrirDiferenciais(1);

// Fecha a ficha de diferenciais
AbrirDiferenciais(0);
```

---

## Cores e tipografia

Tema **verde imersivo** do Mori Mori — Miranda de Castro:

| Token CSS | Valor | Papel |
|-----------|-------|-------|
| `--bg` (fundo) | `#325825` | Verde-escuro principal (fundo) — cor primária |
| `--surface` | `#073C28` | Superfície de card |
| `--dark` (foreground) | `#EAFFF7` | Texto/ícones (verde-claro) — cor secundária |
| `--accent` | `#EAFFF7` | Destaque / estado ativo (usa a secundária sobre fundo escuro) |
| Fonte títulos | Cormorant Garamond | — |
| Fonte UI | Inter | — |

> Plantas técnicas mantêm **fundo claro** no card (`#EAFFF7`, para legibilidade do desenho), com texto verde-escuro (`#325825`) — a mesma dupla primária/secundária, com os papéis invertidos.

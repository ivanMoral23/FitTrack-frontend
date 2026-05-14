// Minimalist GymTracker icon: violet #7C3AED background + white dumbbell
const zlib = require('zlib');
const fs   = require('fs');
const path = require('path');

const W = 1024, H = 1024;

// ── PNG helpers ───────────────────────────────────────────────────────────
const crcTable = new Uint32Array(256);
for (let i = 0; i < 256; i++) {
  let c = i;
  for (let j = 0; j < 8; j++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
  crcTable[i] = c;
}
function crc32(buf) {
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) crc = crcTable[(crc ^ buf[i]) & 0xFF] ^ (crc >>> 8);
  return (crc ^ 0xFFFFFFFF) >>> 0;
}
function makeChunk(type, data) {
  const t   = Buffer.from(type, 'ascii');
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const crcBuf = Buffer.concat([t, data]);
  const crcVal = Buffer.alloc(4); crcVal.writeUInt32BE(crc32(crcBuf));
  return Buffer.concat([len, t, data, crcVal]);
}
function encodePng(pixelBuf, w, h) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; // RGBA
  const rawRows = Buffer.alloc(h * (1 + w * 4));
  for (let y = 0; y < h; y++) {
    rawRows[y * (1 + w * 4)] = 0;
    pixelBuf.copy(rawRows, y * (1 + w * 4) + 1, y * w * 4, (y + 1) * w * 4);
  }
  const compressed = zlib.deflateSync(rawRows, { level: 6 });
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    makeChunk('IHDR', ihdr),
    makeChunk('IDAT', compressed),
    makeChunk('IEND', Buffer.alloc(0)),
  ]);
}
function scaleDown(src, sw, sh, dw, dh) {
  const dst = Buffer.alloc(dw * dh * 4);
  for (let y = 0; y < dh; y++) {
    for (let x = 0; x < dw; x++) {
      const sx0 = Math.floor(x * sw / dw), sx1 = Math.min(sw-1, Math.floor((x+1)*sw/dw));
      const sy0 = Math.floor(y * sh / dh), sy1 = Math.min(sh-1, Math.floor((y+1)*sh/dh));
      let rr=0, gg=0, bb=0, cnt=0;
      for (let sy=sy0; sy<=sy1; sy++)
        for (let sx=sx0; sx<=sx1; sx++) {
          const si=(sy*sw+sx)*4; rr+=src[si]; gg+=src[si+1]; bb+=src[si+2]; cnt++;
        }
      const di=(y*dw+x)*4;
      dst[di]=rr/cnt|0; dst[di+1]=gg/cnt|0; dst[di+2]=bb/cnt|0; dst[di+3]=255;
    }
  }
  return dst;
}

// ── Pixel buffer ──────────────────────────────────────────────────────────
const img = Buffer.alloc(W * H * 4);

function distPt(x, y, cx, cy) { return Math.sqrt((x-cx)**2+(y-cy)**2); }

function setAA(x, y, r, g, b, cov) {
  if (x<0||x>=W||y<0||y>=H||cov<=0) return;
  const i=(y*W+x)*4;
  img[i]  =Math.round(img[i]  *(1-cov)+r*cov);
  img[i+1]=Math.round(img[i+1]*(1-cov)+g*cov);
  img[i+2]=Math.round(img[i+2]*(1-cov)+b*cov);
  img[i+3]=255;
}

function fillRR(rx1, ry1, rx2, ry2, rad, r, g, b) {
  for (let y=Math.floor(ry1); y<=Math.ceil(ry2); y++) {
    for (let x=Math.floor(rx1); x<=Math.ceil(rx2); x++) {
      const inCorner =
        (x<rx1+rad&&y<ry1+rad)||(x>rx2-rad&&y<ry1+rad)||
        (x<rx1+rad&&y>ry2-rad)||(x>rx2-rad&&y>ry2-rad);
      let cov;
      if (inCorner) {
        const cx=x<rx1+rad?rx1+rad:rx2-rad;
        const cy=y<ry1+rad?ry1+rad:ry2-rad;
        cov=Math.max(0,Math.min(1,rad-distPt(x,y,cx,cy)+0.5));
      } else {
        cov=Math.max(0,Math.min(1,Math.min(x-rx1,rx2-x,y-ry1,ry2-y)+0.5));
      }
      setAA(x,y,r,g,b,cov);
    }
  }
}

// ── Background: violet #7C3AED ────────────────────────────────────────────
for (let i=0; i<W*H; i++) {
  img[i*4]=124; img[i*4+1]=58; img[i*4+2]=237; img[i*4+3]=255;
}

// ── White dumbbell, horizontal, centred ──────────────────────────────────
const WR=255, WG=255, WB=255;

// bar
fillRR(310, 492, 714, 532, 20, WR, WG, WB);
// collars
fillRR(250, 444, 310, 580, 14, WR, WG, WB);
fillRR(714, 444, 774, 580, 14, WR, WG, WB);
// inner plates
fillRR(170, 402, 250, 622, 22, WR, WG, WB);
fillRR(774, 402, 854, 622, 22, WR, WG, WB);
// outer plates
fillRR(98,  336, 178, 688, 30, WR, WG, WB);
fillRR(846, 336, 926, 688, 30, WR, WG, WB);

// ── Output ────────────────────────────────────────────────────────────────
const resDir = path.join('..','android','app','src','main','res');
const sizes = [
  { folder:'mipmap-mdpi',    size:48  },
  { folder:'mipmap-hdpi',    size:72  },
  { folder:'mipmap-xhdpi',   size:96  },
  { folder:'mipmap-xxhdpi',  size:144 },
  { folder:'mipmap-xxxhdpi', size:192 },
];

fs.writeFileSync('app_icon.png', encodePng(img, W, H));
console.log('Saved app_icon.png (1024x1024)');

for (const {folder, size} of sizes) {
  const scaled = scaleDown(img, W, H, size, size);
  const outPath = path.join(resDir, folder, 'ic_launcher.png');
  fs.writeFileSync(outPath, encodePng(scaled, size, size));
  console.log(`Saved ${outPath} (${size}x${size})`);
}

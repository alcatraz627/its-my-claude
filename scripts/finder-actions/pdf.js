// Basic PDF jobs done with macOS's own PDF framework, so nothing has to be installed.
// Every job writes a new file next to the first input and never touches the originals.
// Usage: osascript -l JavaScript pdf.js <merge|shrink|images> <files...>
ObjC.import("PDFKit");
ObjC.import("AppKit");

function url(p) { return $.NSURL.fileURLWithPath(p); }

// "a.pdf" -> "a (suffix).pdf", or "a (suffix 2).pdf" when that name is taken.
function freeName(path, suffix, ext) {
  const dir = path.replace(/\/[^/]*$/, "");
  const stem = path.replace(/^.*\//, "").replace(/\.[^.]*$/, "");
  const fm = $.NSFileManager.defaultManager;
  let n = 1, out;
  do {
    out = `${dir}/${stem} (${suffix}${n > 1 ? " " + n : ""}).${ext}`;
    n++;
  } while (fm.fileExistsAtPath(out));
  return out;
}

function open(p) {
  const doc = $.PDFDocument.alloc.initWithURL(url(p));
  if (doc.isNil()) throw new Error(`not a readable PDF: ${p}`);
  return doc;
}

function run(argv) {
  const [job, ...files] = argv;
  if (job === "merge") {
    const out = open(files[0]);
    for (const f of files.slice(1)) {
      const doc = open(f);
      for (let i = 0; i < doc.pageCount; i++) out.insertPageAtIndex(doc.pageAtIndex(i), out.pageCount);
    }
    const dest = freeName(files[0], "merged", "pdf");
    out.writeToURL(url(dest));
    return dest;
  }
  if (job === "shrink") {
    // Re-draws every page as a medium-quality JPEG. Made for scans and photo
    // PDFs; text in the result can no longer be selected. Apple's own
    // "Reduce File Size" filter is not used because it often grows the file.
    const made = [];
    for (const f of files) {
      const doc = open(f);
      const out = $.PDFDocument.alloc.init;
      for (let i = 0; i < doc.pageCount; i++) {
        const page = doc.pageAtIndex(i);
        const box = page.boundsForBox($.kPDFDisplayBoxMediaBox);
        // About 150 dpi for a normal page, but never past 2000 px on the long
        // edge: a PDF made from a photo already has pages as large as the photo.
        const scale = Math.min(150 / 72, 2000 / Math.max(box.size.width, box.size.height));
        const img = page.thumbnailOfSizeForBox($.NSMakeSize(box.size.width * scale, box.size.height * scale), $.kPDFDisplayBoxMediaBox);
        // PDFKit places an image at its pixel size; UpscaleIfSmaller stretches it
        // across the original page box so the page keeps its printed size.
        const opts = $({
          PDFPageImageInitializationOptionMediaBox: $.NSValue.valueWithRect(box),
          PDFPageImageInitializationOptionUpscaleIfSmaller: true,
          PDFPageImageInitializationOptionCompressionQuality: 0.6,
        });
        out.insertPageAtIndex($.PDFPage.alloc.initWithImageOptions(img, opts), out.pageCount);
      }
      const dest = freeName(f, "smaller", "pdf");
      out.writeToURL(url(dest));
      made.push(dest);
    }
    return made.join("\n");
  }
  if (job === "images") {
    const made = [];
    for (const f of files) {
      const doc = open(f);
      for (let i = 0; i < doc.pageCount; i++) {
        const page = doc.pageAtIndex(i);
        const box = page.boundsForBox($.kPDFDisplayBoxMediaBox);
        // 144 dpi keeps text sharp; the 4000 px cap stops photo-sized pages from exploding.
        const scale = Math.min(2, 4000 / Math.max(box.size.width, box.size.height));
        const img = page.thumbnailOfSizeForBox($.NSMakeSize(box.size.width * scale, box.size.height * scale), $.kPDFDisplayBoxMediaBox);
        const rep = $.NSBitmapImageRep.imageRepWithData(img.TIFFRepresentation);
        const png = rep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $({}));
        const dest = freeName(f, `page ${i + 1}`, "png");
        png.writeToFileAtomically(dest, true);
        made.push(dest);
      }
    }
    return made.join("\n");
  }
  throw new Error(`unknown job: ${job}`);
}

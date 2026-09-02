import { readFileSync, writeFileSync } from "node:fs";
import { createDecipheriv } from "node:crypto";

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) {
  throw new Error("Usage: node decrypt_release.mjs INPUT OUTPUT");
}

const keyHex = process.env.ARCHIVE_KEY_HEX ?? "";
if (!/^[0-9a-fA-F]{64}$/.test(keyHex)) {
  throw new Error("ARCHIVE_KEY_HEX must be a 64-character hexadecimal secret.");
}

const payload = readFileSync(inputPath);
const magic = payload.subarray(0, 9).toString("ascii");
if (magic !== "OPNMFENC1") {
  throw new Error("Encrypted archive header is invalid.");
}

const iv = payload.subarray(9, 21);
const tag = payload.subarray(21, 37);
const ciphertext = payload.subarray(37);
const decipher = createDecipheriv(
  "aes-256-gcm",
  Buffer.from(keyHex, "hex"),
  iv,
);
decipher.setAuthTag(tag);
const plaintext = Buffer.concat([
  decipher.update(ciphertext),
  decipher.final(),
]);
writeFileSync(outputPath, plaintext);

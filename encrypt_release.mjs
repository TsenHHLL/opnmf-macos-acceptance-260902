import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { createCipheriv, randomBytes } from "node:crypto";

const [inputPath, outputPath, keyPath] = process.argv.slice(2);
if (!inputPath || !outputPath || !keyPath) {
  throw new Error("Usage: node encrypt_release.mjs INPUT OUTPUT KEY_FILE");
}

const key = randomBytes(32);
const iv = randomBytes(12);
const cipher = createCipheriv("aes-256-gcm", key, iv);
const plaintext = readFileSync(inputPath);
const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
const tag = cipher.getAuthTag();
const magic = Buffer.from("OPNMFENC1", "ascii");

writeFileSync(outputPath, Buffer.concat([magic, iv, tag, ciphertext]));
mkdirSync(dirname(keyPath), { recursive: true });
writeFileSync(keyPath, `${key.toString("hex")}\n`, { mode: 0o600 });

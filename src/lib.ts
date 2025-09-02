import * as path from "path";
import * as fs from "fs";
import { shell } from "electron";
import { ImageData } from "alt1";

declare global {
	//TODO webpack npm package should fix this
	var __non_webpack_require__: typeof require;
}

//Error that is visible to user
export class UserError extends Error { }

export const schemestring = "alt1lite";
export const weborigin = "https://runeapps.org";

//needed because node-fetch tries to be correct by choking on BOM
export async function readJsonWithBOM(res: { text(): Promise<string> }) {
	let text = await res.text()
	if (text.charCodeAt(0) === 0xFEFF) {
		text = text.substr(1)
	}
	return JSON.parse(text);
}

export function sameDomainResolve(base: URL | string, suburl: string) {
	if (typeof base == "string") { base = new URL(base); }
	let url = new URL(suburl, base);
	if (url.origin != base.origin) { throw new UserError("url must be from same domain as context"); }
	return url;
}

//Relative path from electron entry file
export function relPath(relpath: string) {
	return path.join(__dirname, relpath);
}

export function patchImageDataShow() {
	if (process.env.NODE_ENV === "development") {
		(ImageData.prototype.show as any) = function(this: ImageData) { showImageData(this); }
	}
}

export async function showImageData(img: ImageData) {
	if (process.env.NODE_ENV === "development") {
		let dir = "./debugimgs";
		fs.mkdirSync(dir, { recursive: true });
		let filename = path.resolve(`${dir}/debugimg_${Math.random() * 1000 | 0}.png`);
		fs.writeFileSync(filename, await img.toFileBytes("image/png"));
		shell.openPath(filename);
	}
}

export function delay(t: number) {
	return new Promise(d => setTimeout(d, t));
}

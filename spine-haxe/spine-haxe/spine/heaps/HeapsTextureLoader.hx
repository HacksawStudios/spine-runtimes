/****************************************************************************
 * Spine Runtimes License Agreement
 * Last updated April 5, 2025. Replaces all prior versions.
 *
 * Copyright (c) 2013-2025, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software
 * or otherwise create derivative works of the Spine Runtimes (collectively,
 * "Products"), provided that each user of the Products must obtain their own
 * Spine Editor license and redistribution of the Products in any form must
 * include this license and copyright notice.
 *
 * THE SPINE RUNTIMES ARE PROVIDED BY ESOTERIC SOFTWARE LLC "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ESOTERIC SOFTWARE LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES,
 * BUSINESS INTERRUPTION, OR LOSS OF USE, DATA, OR PROFITS) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THE SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine.heaps;

import StringTools;
import h2d.Tile;
import spine.SpineException;
import spine.atlas.TextureAtlasPage;
import spine.atlas.TextureAtlasRegion;
import spine.atlas.TextureLoader;

typedef TileLoader = String->Tile;
typedef TileDisposer = Tile->Void;

/** Loads Spine atlas pages into Heaps tiles. */
class HeapsTextureLoader implements TextureLoader {
	private var basePath:String;
	private var tileLoader:TileLoader;
	private var tileDisposer:Null<TileDisposer>;

	/**
	 * @param atlasPath Path to the atlas text file.
	 * @param tileLoader Callback that resolves a page path to a Heaps tile.
	 * @param tileDisposer Optional callback used when atlas pages are unloaded.
	 */
	public function new(atlasPath:String, tileLoader:TileLoader, ?tileDisposer:TileDisposer) {
		if (tileLoader == null)
			throw new SpineException("tileLoader cannot be null.");
		this.basePath = resolveBasePath(atlasPath);
		this.tileLoader = tileLoader;
		this.tileDisposer = tileDisposer;
	}

	public function loadPage(page:TextureAtlasPage, path:String):Void {
		var normalizedPath = StringTools.trim(path);
		if (normalizedPath == "")
			throw new SpineException("Atlas page path cannot be empty.");
		var resolvedPath = resolvePath(basePath, normalizedPath);
		var tile = tileLoader(resolvedPath);
		if (tile == null)
			throw new SpineException("Could not load atlas page texture " + resolvedPath);
		page.texture = tile;
		if (page.width <= 0)
			page.width = Std.int(Math.max(1.0, tile.width));
		if (page.height <= 0)
			page.height = Std.int(Math.max(1.0, tile.height));
	}

	public function loadRegion(region:TextureAtlasRegion):Void {
		if (region.page == null || region.page.texture == null)
			throw new SpineException("Atlas region page texture is missing for " + region.name);
		region.texture = region.page.texture;
		if (!Std.isOfType(region.page.texture, Tile))
			return;

		final pageTile:Tile = cast region.page.texture;
		final texture = pageTile.getTexture();
		if (texture == null)
			throw new SpineException("Atlas page texture is missing for " + region.name);

		final atlasPageWidth = Math.max(1.0, region.page.width);
		final atlasPageHeight = Math.max(1.0, region.page.height);
		final scaleX = pageTile.width / atlasPageWidth;
		final scaleY = pageTile.height / atlasPageHeight;
		final pageX = pageTile.x + region.x * scaleX;
		final pageY = pageTile.y + region.y * scaleY;
		final regionWidth = region.width * scaleX;
		final regionHeight = region.height * scaleY;

		region.u = pageX / texture.width;
		region.v = pageY / texture.height;
		if (region.degrees == 90) {
			region.u2 = (pageX + regionHeight) / texture.width;
			region.v2 = (pageY + regionWidth) / texture.height;
		} else {
			region.u2 = (pageX + regionWidth) / texture.width;
			region.v2 = (pageY + regionHeight) / texture.height;
		}
	}

	public function unloadPage(page:TextureAtlasPage):Void {
		if (page.texture != null && tileDisposer != null && Std.isOfType(page.texture, Tile)) {
			tileDisposer(cast page.texture);
		}
		page.texture = null;
		for (region in page.regions) {
			region.texture = null;
		}
	}

	private static function resolveBasePath(atlasPath:String):String {
		var normalizedPath = atlasPath == null ? "" : atlasPath.split("\\").join("/");
		var slashIndex = normalizedPath.lastIndexOf("/");
		return slashIndex == -1 ? "" : normalizedPath.substring(0, slashIndex);
	}

	private static function resolvePath(basePath:String, relativePath:String):String {
		var normalizedRelativePath = relativePath.split("\\").join("/");
		if (StringTools.startsWith(normalizedRelativePath, "/") || normalizedRelativePath.indexOf(":") == 1)
			return normalizedRelativePath;
		return basePath == "" ? normalizedRelativePath : basePath + "/" + normalizedRelativePath;
	}
}

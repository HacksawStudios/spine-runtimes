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

import h2d.BlendMode;
import h2d.Tile;
import h3d.mat.Data.Face;
import h3d.mat.Material;
import h3d.scene.Mesh;
import h3d.scene.Object;
import spine.Color;

/** A Heaps mesh that draws one Spine slot. */
class SkeletonMesh extends Mesh {
	private static inline var SLOT_Z_STEP:Float = 0.1;

	private var geometry:SpineMeshPrimitive;
	private var heapsMaterial:Material;

	public function new(?parent:Object) {
		geometry = new SpineMeshPrimitive();
		heapsMaterial = h3d.mat.MaterialSetup.current.createMaterial();
		heapsMaterial.mainPass.depthWrite = false;
		heapsMaterial.mainPass.culling = Face.None;
		super(geometry, heapsMaterial, parent);
	}

	public function setOrder(order:Int):Void {
		z = order * SLOT_Z_STEP;
	}

	public function apply(tile:Tile, vertices:Array<Float>, uvs:Array<Float>, indices:Array<Int>, slotBlendMode:spine.BlendMode,
			blendModeOverride:Null<BlendMode>, color:Color):Void {
		heapsMaterial.texture = tile.getTexture();
		applyBlendMode(slotBlendMode, blendModeOverride);
		heapsMaterial.color.set(color.r, color.g, color.b, color.a);
		geometry.applyGeometry(vertices, uvs, indices);
		visible = indices.length > 0;
	}

	public function hide():Void {
		visible = false;
	}

	public function dispose():Void {
		remove();
		geometry.dispose();
	}

	private function applyBlendMode(slotBlendMode:spine.BlendMode, blendModeOverride:Null<BlendMode>):Void {
		var pass = heapsMaterial.mainPass;
		pass.depthWrite = false;
		pass.setPassName("alpha");
		pass.setBlendMode(blendModeOverride != null ? blendModeOverride : toBlendMode(slotBlendMode));
	}

	public static function toBlendMode(spineBlendMode:spine.BlendMode):BlendMode {
		return switch spineBlendMode {
			case normal:
				BlendMode.Alpha;
			case additive:
				BlendMode.Add;
			case multiply:
				BlendMode.Multiply;
			case screen:
				BlendMode.Screen;
			default:
				BlendMode.Alpha;
		};
	}
}

private class SpineMeshPrimitive extends h3d.prim.DynamicPrimitive {
	public function new() {
		super(hxd.BufferFormat.POS3D_NORMAL_UV);
	}

	public function applyGeometry(vertices:Array<Float>, uvs:Array<Float>, indices:Array<Int>):Void {
		var vertexCount = Std.int(vertices.length / 2);
		var hasGeometry = vertexCount > 0 && indices.length > 0;
		if (!hasGeometry) {
			bounds.empty();
			getBuffer(0);
			getIndexes(0);
			flush();
			return;
		}

		var buffer = getBuffer(vertexCount);
		bounds.empty();
		for (vertexIndex in 0...vertexCount) {
			var sourceOffset = vertexIndex * 2;
			var targetOffset = vertexIndex * 8;
			var x = vertices[sourceOffset];
			var y = vertices[sourceOffset + 1];
			buffer[targetOffset] = x;
			buffer[targetOffset + 1] = y;
			buffer[targetOffset + 2] = 0.0;
			buffer[targetOffset + 3] = 0.0;
			buffer[targetOffset + 4] = 0.0;
			buffer[targetOffset + 5] = 1.0;
			buffer[targetOffset + 6] = sourceOffset + 1 < uvs.length ? uvs[sourceOffset] : 0.0;
			buffer[targetOffset + 7] = sourceOffset + 1 < uvs.length ? uvs[sourceOffset + 1] : 0.0;
			bounds.addPos(x, y, 0.0);
		}

		var indexBuffer = getIndexes(indices.length);
		for (index in 0...indices.length) {
			indexBuffer[index] = indices[index];
		}
		flush();
	}
}

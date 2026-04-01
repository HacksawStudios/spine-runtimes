/******************************************************************************
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

package heapsExamples;

import h2d.Graphics;
import heapsExamples.Scene.SceneManager;
import spine.Rectangle;
import spine.heaps.SkeletonRenderer;

class AnimationBoundExample extends Scene {
	private var clippingRenderer:SkeletonRenderer;
	private var noClippingRenderer:SkeletonRenderer;
	private var clippingRect:Rectangle;
	private var noClippingRect:Rectangle;
	private var clippingOverlay:Graphics;
	private var noClippingOverlay:Graphics;

	override public function load():Void {
		setBackgroundColor(0x333333);
		clippingRenderer = createSkeletonRenderer("assets/spineboy.atlas", "assets/spineboy-pro.json");
		clippingRenderer.stateData.defaultMix = 0.25;
		clippingRenderer.state.setAnimationByName(0, "portal", true);
		clippingRect = getAnimationBounds(clippingRenderer.skeletonData, "portal", true);

		noClippingRenderer = createSkeletonRenderer("assets/spineboy.atlas", "assets/spineboy-pro.json");
		noClippingRenderer.stateData.defaultMix = 0.25;
		noClippingRenderer.state.setAnimationByName(0, "portal", true);
		noClippingRect = getAnimationBounds(noClippingRenderer.skeletonData, "portal", false);

		clippingOverlay = createOverlayGraphics();
		noClippingOverlay = createOverlayGraphics();
		addText("Animation bound without clipping", 75, 350);
		addText("Animation bound with clipping", 420, 350);
		addText("Red area is the animation bound", 250, 400);
	}

	override public function layout():Void {
		var noClippingPosition = screenToWorld(app.engine.width / 3, app.engine.height * 0.5, noClippingRenderer.object.z);
		noClippingRenderer.object.scaleX = 0.2;
		noClippingRenderer.object.scaleY = 0.2;
		noClippingRenderer.object.setPosition(noClippingPosition.x, noClippingPosition.y, noClippingPosition.z);
		var clippingPosition = screenToWorld(app.engine.width / 3 * 2, app.engine.height * 0.5, clippingRenderer.object.z);
		clippingRenderer.object.scaleX = 0.2;
		clippingRenderer.object.scaleY = 0.2;
		clippingRenderer.object.setPosition(clippingPosition.x, clippingPosition.y, clippingPosition.z);
		drawBoundsOutline(noClippingOverlay, getRectScreenRect(noClippingRenderer, noClippingRect));
		drawBoundsOutline(clippingOverlay, getRectScreenRect(clippingRenderer, clippingRect));
	}

	override public function onScreenClick(event:hxd.Event):Void {
		SceneManager.getInstance().switchScene(new ControlBonesExample());
	}

	private function drawBoundsOutline(graphics:Graphics, rect:{xMin:Float, xMax:Float, yMin:Float, yMax:Float}):Void {
		graphics.clear();
		graphics.lineStyle(0.5, 0xC70000, 1);
		graphics.drawRect(rect.xMin, rect.yMin, rect.xMax - rect.xMin, rect.yMax - rect.yMin);
	}
}

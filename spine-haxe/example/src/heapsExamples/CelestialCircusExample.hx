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

import h3d.col.Point;
import heapsExamples.Scene.SceneManager;
import hxd.Event.EventKind;
import hxd.Event;
import spine.heaps.SkeletonRenderer;

class CelestialCircusExample extends Scene {
	private var skeletonRenderer:SkeletonRenderer;
	private var consumeClick = false;
	private var dragMoved = false;
	private var lastWorldPoint:Point;

	override public function load():Void {
		setBackgroundColor(0x333333);
		skeletonRenderer = createSkeletonRenderer("assets/celestial-circus.atlas", "assets/celestial-circus-pro.skel");
		skeletonRenderer.stateData.defaultMix = 0.25;
		skeletonRenderer.state.setAnimationByName(0, "eyeblink-long", true);
		addText("Drag Celeste to move her around");
		addText("Click the background for next scene", 10, 30);
	}

	override public function layout():Void {
		var position = screenToWorld(app.engine.width * 0.5, app.engine.height / 1.5, skeletonRenderer.object.z);
		skeletonRenderer.object.scaleX = 0.2;
		skeletonRenderer.object.scaleY = 0.2;
		skeletonRenderer.object.setPosition(position.x, position.y, position.z);
	}

	override public function onScreenPush(event:Event):Void {
		if (!rendererContainsScreenPoint(skeletonRenderer, event.relX, event.relY))
			return;
		consumeClick = true;
		dragMoved = false;
		lastWorldPoint = screenToWorld(event.relX, event.relY, skeletonRenderer.object.z);
		screen.startCapture(handleDragCapture, function() lastWorldPoint = null, event.touchId);
	}

	private function handleDragCapture(event:Event):Void {
		switch (event.kind) {
			case EventKind.EMove:
				var nextWorldPoint = screenToWorld(event.relX, event.relY, skeletonRenderer.object.z);
				var dx = nextWorldPoint.x - lastWorldPoint.x;
				var dy = nextWorldPoint.y - lastWorldPoint.y;
				if (Math.abs(dx) > 0.0001 || Math.abs(dy) > 0.0001)
					dragMoved = true;
				skeletonRenderer.object.x += dx;
				skeletonRenderer.object.y += dy;
				skeletonRenderer.skeleton.physicsTranslate(dx / skeletonRenderer.object.scaleX, dy / skeletonRenderer.object.scaleY);
				lastWorldPoint = nextWorldPoint;
			case EventKind.ERelease, EventKind.EReleaseOutside:
				screen.stopCapture();
			default:
		}
	}

	override public function onScreenClick(event:Event):Void {
		if (consumeClick) {
			consumeClick = false;
			return;
		}
		SceneManager.getInstance().switchScene(new SnowglobeExample());
	}
}

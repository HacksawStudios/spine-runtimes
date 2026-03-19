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
import h3d.col.Point;
import heapsExamples.Scene.SceneManager;
import hxd.Event.EventKind;
import hxd.Event;
import spine.Bone;
import spine.heaps.SkeletonRenderer;

private typedef ControlHandle = {
	var bone:Bone;
	var marker:Graphics;
	var screenX:Float;
	var screenY:Float;
}

class ControlBonesExample extends Scene {
	private static inline var HANDLE_RADIUS = 8.0;

	private var skeletonRenderer:SkeletonRenderer;
	private var layoutWidth = 1.0;
	private var controlHandles:Array<ControlHandle> = [];
	private var activeHandle:Null<ControlHandle> = null;
	private var dragSkeleton = false;
	private var dragMoved = false;
	private var consumeClick = false;
	private var lastWorldPoint:Point;
	private var lastScreenX = 0.0;
	private var lastScreenY = 0.0;

	override public function load():Void {
		skeletonRenderer = createSkeletonRenderer("assets/stretchyman.atlas", "assets/stretchyman-pro.skel");
		layoutWidth = Math.max(1.0, skeletonRenderer.getBounds(false).width);
		skeletonRenderer.stateData.defaultMix = 0.25;
		skeletonRenderer.state.setAnimationByName(0, "idle", true);
		addText("Drag the purple circles or Stretchyman.");
		addText("Click the background for next scene", 10, 30);

		for (boneName in [
			"back-arm-ik-target",
			"back-leg-ik-target",
			"front-arm-ik-target",
			"front-leg-ik-target"
		]) {
			var marker = createOverlayGraphics();
			marker.beginFill(0xFF00FF, 1);
			marker.drawCircle(0, 0, HANDLE_RADIUS);
			marker.endFill();
			controlHandles.push({
				bone: skeletonRenderer.skeleton.findBone(boneName),
				marker: marker,
				screenX: 0,
				screenY: 0
			});
		}

		skeletonRenderer.beforeUpdateWorldTransforms = renderer -> {
			for (handle in controlHandles) {
				var worldPoint = screenToWorld(handle.screenX, handle.screenY, renderer.object.z);
				var point = [
					(worldPoint.x - renderer.object.x) / renderer.object.scaleX,
					(worldPoint.y - renderer.object.y) / renderer.object.scaleY
				];
				if (handle.bone.parent != null) {
					handle.bone.parent.worldToLocal(point);
				} else {
					handle.bone.worldToLocal(point);
				}
				handle.bone.x = point[0];
				handle.bone.y = point[1];
			}
		};
	}

	override public function layout():Void {
		var scale = app.engine.width / layoutWidth * 0.25;
		var position = screenToWorld(app.engine.width * 0.5, app.engine.height * 0.9, skeletonRenderer.object.z);
		skeletonRenderer.object.scaleX = scale;
		skeletonRenderer.object.scaleY = scale;
		skeletonRenderer.object.setPosition(position.x, position.y, position.z);
		syncHandlesToBones();
	}

	override public function afterRenderersUpdated(dt:Float):Void {
		if (!dragSkeleton) {
			syncHandlesToBones();
		}
	}

	override public function onScreenPush(event:Event):Void {
		lastScreenX = event.relX;
		lastScreenY = event.relY;
		activeHandle = findHandle(event.relX, event.relY);
		if (activeHandle != null) {
			consumeClick = true;
			dragMoved = false;
			startCapture();
			return;
		}
		if (rendererContainsScreenPoint(skeletonRenderer, event.relX, event.relY)) {
			consumeClick = true;
			dragSkeleton = true;
			dragMoved = false;
			lastWorldPoint = screenToWorld(event.relX, event.relY, skeletonRenderer.object.z);
			startCapture();
		}
	}

	private function startCapture():Void {
		screen.startCapture(handleCapture, function() {
			activeHandle = null;
			dragSkeleton = false;
			lastWorldPoint = null;
		}, null);
	}

	private function handleCapture(event:Event):Void {
		switch (event.kind) {
			case EventKind.EMove:
				var dxScreen = event.relX - lastScreenX;
				var dyScreen = event.relY - lastScreenY;
				if (Math.abs(dxScreen) > 0.0001 || Math.abs(dyScreen) > 0.0001)
					dragMoved = true;
				if (activeHandle != null) {
					activeHandle.screenX = event.relX;
					activeHandle.screenY = event.relY;
					positionHandle(activeHandle);
				} else if (dragSkeleton) {
					var nextWorldPoint = screenToWorld(event.relX, event.relY, skeletonRenderer.object.z);
					var dx = nextWorldPoint.x - lastWorldPoint.x;
					var dy = nextWorldPoint.y - lastWorldPoint.y;
					skeletonRenderer.object.x += dx;
					skeletonRenderer.object.y += dy;
					lastWorldPoint = nextWorldPoint;
				}
				lastScreenX = event.relX;
				lastScreenY = event.relY;
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
		SceneManager.getInstance().switchScene(new EventsExample());
	}

	private function syncHandlesToBones():Void {
		for (handle in controlHandles) {
			if (handle == activeHandle)
				continue;
			var point = getBoneScreenPoint(skeletonRenderer, handle.bone);
			handle.screenX = point.x;
			handle.screenY = point.y;
			positionHandle(handle);
		}
	}

	private function positionHandle(handle:ControlHandle):Void {
		handle.marker.x = handle.screenX;
		handle.marker.y = handle.screenY;
	}

	private function findHandle(x:Float, y:Float):Null<ControlHandle> {
		for (handle in controlHandles) {
			var dx = handle.screenX - x;
			var dy = handle.screenY - y;
			if (dx * dx + dy * dy <= HANDLE_RADIUS * HANDLE_RADIUS * 4)
				return handle;
		}
		return null;
	}
}

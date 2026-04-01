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

import StringTools;
import h2d.Graphics;
import h2d.Interactive;
import h2d.Object as H2dObject;
import h2d.Text;
import h3d.col.Bounds;
import h3d.col.Plane;
import h3d.col.Point;
import h3d.scene.Object as H3dObject;
import hxd.Event;
import hxd.res.DefaultFont;
import spine.Bone;
import spine.Physics;
import spine.Rectangle;
import spine.Skeleton;
import spine.SkeletonClipping;
import spine.SkeletonData;
import spine.animation.Animation;
import spine.animation.AnimationStateData;
import spine.animation.MixBlend;
import spine.animation.MixDirection;
import spine.atlas.TextureAtlas;
import spine.heaps.HeapsTextureLoader;
import spine.heaps.SkeletonRenderer;

private typedef ScreenRect = {
	var xMin:Float;
	var xMax:Float;
	var yMin:Float;
	var yMax:Float;
}

class SceneManager {
	private static var instance:SceneManager;

	public static function initialize(app:MainHeaps):Void {
		instance = new SceneManager(app);
	}

	public static function getInstance():SceneManager {
		if (instance == null)
			throw "SceneManager has not been initialized.";
		return instance;
	}

	public final app:MainHeaps;

	private var currentScene:Scene;

	private function new(app:MainHeaps) {
		this.app = app;
	}

	public function switchScene(newScene:Scene):Void {
		if (currentScene != null)
			currentScene.dispose();
		currentScene = newScene;
		currentScene.load();
		currentScene.onResize();
	}

	public function update(dt:Float):Void {
		if (currentScene != null)
			currentScene.update(dt);
	}

	public function resize():Void {
		if (currentScene != null)
			currentScene.onResize();
	}
}

class Scene {
	private final manager:SceneManager;

	public final background:Graphics;
	public final overlay:H2dObject;
	public final world:H3dObject;
	public final screen:Interactive;

	private var backgroundColor:Int = 0x000000;
	private var allRenderers:Array<SkeletonRenderer> = [];
	private var animatedRenderers:Array<SkeletonRenderer> = [];

	public function new() {
		Bone.yDown = false;
		manager = SceneManager.getInstance();
		world = new H3dObject(manager.app.s3d);
		var uiRoot = new H2dObject(manager.app.s2d);
		background = new Graphics(uiRoot);
		overlay = new H2dObject(uiRoot);
		screen = new Interactive(1, 1, uiRoot);
		screen.backgroundColor = 0x00000000;
		screen.onPush = onScreenPush;
		screen.onMove = onScreenMove;
		screen.onRelease = onScreenRelease;
		screen.onClick = onScreenClick;
		configureCamera();
	}

	public var app(get, never):MainHeaps;

	private function get_app():MainHeaps {
		return manager.app;
	}

	public function load():Void {}

	public function update(dt:Float):Void {
		for (renderer in animatedRenderers) {
			renderer.update(dt);
		}
		afterRenderersUpdated(dt);
	}

	public function dispose():Void {
		for (renderer in allRenderers) {
			renderer.dispose();
		}
		allRenderers = [];
		animatedRenderers = [];
		world.remove();
		background.parent.remove();
	}

	public function onResize():Void {
		configureCamera();
		screen.width = app.engine.width;
		screen.height = app.engine.height;
		redrawBackground();
		layout();
	}

	public function layout():Void {}

	public function afterRenderersUpdated(dt:Float):Void {}

	public function onScreenPush(event:Event):Void {}

	public function onScreenMove(event:Event):Void {}

	public function onScreenRelease(event:Event):Void {}

	public function onScreenClick(event:Event):Void {}

	public function setBackgroundColor(color:Int):Void {
		backgroundColor = color;
		redrawBackground();
	}

	public function addText(text:String, x:Float = 10, y:Float = 10, color:Int = 0xFFFFFF):Text {
		var label = new Text(DefaultFont.get(), overlay);
		label.text = text;
		label.textColor = color;
		label.x = x;
		label.y = y;
		return label;
	}

	public function createOverlayGraphics():Graphics {
		return new Graphics(overlay);
	}

	public function createSkeletonRenderer(atlasPath:String, skeletonPath:String, scale:Float = 1.0, autoUpdate:Bool = true):SkeletonRenderer {
		var atlas = new TextureAtlas(hxd.Res.load(atlasPath).toText(), new HeapsTextureLoader(atlasPath, path -> hxd.Res.load(path).toTile()));
		var skeletonInput:Dynamic = StringTools.endsWith(skeletonPath,
			".skel") ? hxd.Res.load(skeletonPath).entry.getBytes() : hxd.Res.load(skeletonPath).toText();
		var skeletonData = SkeletonData.from(skeletonInput, atlas, scale);
		var renderer = new SkeletonRenderer(skeletonData, new AnimationStateData(skeletonData), world);
		renderer.refresh();
		allRenderers.push(renderer);
		setRendererAutoUpdate(renderer, autoUpdate);
		return renderer;
	}

	public function setRendererAutoUpdate(renderer:SkeletonRenderer, autoUpdate:Bool):Void {
		animatedRenderers = animatedRenderers.filter(existing -> existing != renderer);
		if (autoUpdate)
			animatedRenderers.push(renderer);
	}

	public function worldToScreen(x:Float, y:Float, z:Float = 0):Point {
		return new Point(x + app.engine.width * 0.5, app.engine.height * 0.5 - y, z);
	}

	public function screenToWorld(screenX:Float, screenY:Float, z:Float = 0):Point {
		return new Point(screenX - app.engine.width * 0.5, app.engine.height * 0.5 - screenY, z);
	}

	public function rendererContainsScreenPoint(renderer:SkeletonRenderer, x:Float, y:Float):Bool {
		var rect = getRendererScreenRect(renderer);
		return x >= rect.xMin && x <= rect.xMax && y >= rect.yMin && y <= rect.yMax;
	}

	public function getRendererScreenRect(renderer:SkeletonRenderer):ScreenRect {
		return projectBounds(renderer.object.getBounds());
	}

	public function getBoneScreenPoint(renderer:SkeletonRenderer, bone:spine.Bone):Point {
		var worldX = renderer.object.x + bone.worldX * renderer.object.scaleX;
		var worldY = renderer.object.y + bone.worldY * renderer.object.scaleY;
		return worldToScreen(worldX, worldY, renderer.object.z);
	}

	public function getRectScreenRect(renderer:SkeletonRenderer, rect:Rectangle):ScreenRect {
		var worldTopLeft = worldToScreen(renderer.object.x + rect.x * renderer.object.scaleX, renderer.object.y + rect.y * renderer.object.scaleY,
			renderer.object.z);
		var worldBottomRight = worldToScreen(renderer.object.x + (rect.x + rect.width) * renderer.object.scaleX,
			renderer.object.y + (rect.y + rect.height) * renderer.object.scaleY, renderer.object.z);
		return {
			xMin: Math.min(worldTopLeft.x, worldBottomRight.x),
			xMax: Math.max(worldTopLeft.x, worldBottomRight.x),
			yMin: Math.min(worldTopLeft.y, worldBottomRight.y),
			yMax: Math.max(worldTopLeft.y, worldBottomRight.y)
		};
	}

	public function drawScreenRect(graphics:Graphics, rect:ScreenRect, color:Int, alpha:Float = 0.35):Void {
		graphics.clear();
		graphics.lineStyle(2, color, 1);
		graphics.beginFill(color, alpha);
		graphics.drawRect(rect.xMin, rect.yMin, rect.xMax - rect.xMin, rect.yMax - rect.yMin);
		graphics.endFill();
	}

	public function getAnimationBounds(skeletonData:SkeletonData, animationName:String, clip:Bool):Rectangle {
		var animation = skeletonData.findAnimation(animationName);
		if (animation == null)
			throw 'Animation not found: $animationName';
		var skeleton = new Skeleton(skeletonData);
		var combined = new Rectangle();
		var hasSample = false;
		var sampleCount = Std.int(Math.max(24, Math.ceil(animation.duration * 30)));
		for (index in 0...sampleCount + 1) {
			var sampleTime = animation.duration == 0 ? 0 : animation.duration * index / sampleCount;
			skeleton.setToSetupPose();
			animation.apply(skeleton, -1, sampleTime, true, null, 1, MixBlend.first, MixDirection.mixIn);
			skeleton.updateWorldTransform(Physics.update);
			var sampleBounds = skeleton.getBounds(clip ? new SkeletonClipping() : null);
			if (!hasSample) {
				combined.x = sampleBounds.x;
				combined.y = sampleBounds.y;
				combined.width = sampleBounds.width;
				combined.height = sampleBounds.height;
				hasSample = true;
			} else {
				var xMin = Math.min(combined.x, sampleBounds.x);
				var yMin = Math.min(combined.y, sampleBounds.y);
				var xMax = Math.max(combined.x + combined.width, sampleBounds.x + sampleBounds.width);
				var yMax = Math.max(combined.y + combined.height, sampleBounds.y + sampleBounds.height);
				combined.x = xMin;
				combined.y = yMin;
				combined.width = xMax - xMin;
				combined.height = yMax - yMin;
			}
		}
		return combined;
	}

	private function redrawBackground():Void {
		background.clear();
		app.engine.backgroundColor = 0xFF000000 | backgroundColor;
	}

	private function configureCamera():Void {
		var camera = app.s3d.camera;
		camera.pos.set(0.0, 0.0, 10.0);
		camera.rightHanded = true;
		camera.target.set(0.0, 0.0, 0.0);
		camera.up.set(0.0, 1.0, 0.0);
		camera.zNear = 0.01;
		camera.zFar = 1000.0;
		camera.orthoBounds = Bounds.fromValues(-app.engine.width * 0.5, -app.engine.height * 0.5, -10.0, app.engine.width, app.engine.height, 20.0);
		camera.update();
	}

	private function projectBounds(bounds:Bounds):ScreenRect {
		var corners = [
			worldToScreen(bounds.xMin, bounds.yMin, bounds.zMin),
			worldToScreen(bounds.xMin, bounds.yMin, bounds.zMax),
			worldToScreen(bounds.xMin, bounds.yMax, bounds.zMin),
			worldToScreen(bounds.xMin, bounds.yMax, bounds.zMax),
			worldToScreen(bounds.xMax, bounds.yMin, bounds.zMin),
			worldToScreen(bounds.xMax, bounds.yMin, bounds.zMax),
			worldToScreen(bounds.xMax, bounds.yMax, bounds.zMin),
			worldToScreen(bounds.xMax, bounds.yMax, bounds.zMax)
		];
		var xMin = Math.POSITIVE_INFINITY;
		var xMax = Math.NEGATIVE_INFINITY;
		var yMin = Math.POSITIVE_INFINITY;
		var yMax = Math.NEGATIVE_INFINITY;
		for (corner in corners) {
			xMin = Math.min(xMin, corner.x);
			xMax = Math.max(xMax, corner.x);
			yMin = Math.min(yMin, corner.y);
			yMax = Math.max(yMax, corner.y);
		}
		return {
			xMin: xMin,
			xMax: xMax,
			yMin: yMin,
			yMax: yMax
		};
	}
}

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

import h2d.Object as H2dObject;
import h2d.Text;
import heapsExamples.Scene.SceneManager;
import spine.animation.TrackEntry;
import spine.heaps.SkeletonRenderer;

class EventsExample extends Scene {
	private var skeletonRenderer:SkeletonRenderer;
	private var textContainer:H2dObject;
	private var logs:Array<Text> = [];
	private var logsNumber = 0;
	private var yOffset = 12;

	override public function load():Void {
		skeletonRenderer = createSkeletonRenderer("assets/spineboy.atlas", "assets/spineboy-pro.skel", 0.5);
		skeletonRenderer.stateData.defaultMix = 0.25;
		skeletonRenderer.state.onStart.add(entry -> log('Started animation ${entry.animation.name}'));
		skeletonRenderer.state.onInterrupt.add(entry -> log('Interrupted animation ${entry.animation.name}'));
		skeletonRenderer.state.onEnd.add(entry -> log('Ended animation ${entry.animation.name}'));
		skeletonRenderer.state.onDispose.add(entry -> log('Disposed animation ${entry.animation.name}'));
		skeletonRenderer.state.onComplete.add(entry -> log('Completed animation ${entry.animation.name}'));
		skeletonRenderer.state.setAnimationByName(0, "walk", true);
		var trackEntry = skeletonRenderer.state.addAnimationByName(0, "run", true, 3);
		trackEntry.onEvent.add((entry, event) -> log('Custom event for ${entry.animation.name}: ${event.data.name}'));
		addText("Click anywhere for next scene");
		textContainer = new H2dObject(overlay);
	}

	override public function layout():Void {
		var position = screenToWorld(app.engine.width * 0.5, app.engine.height * 0.8, skeletonRenderer.object.z);
		skeletonRenderer.object.scaleX = 1.0;
		skeletonRenderer.object.scaleY = 1.0;
		skeletonRenderer.object.setPosition(position.x, position.y, position.z);
	}

	override public function onScreenClick(event:hxd.Event):Void {
		SceneManager.getInstance().switchScene(new BasicExample());
	}

	private function log(text:String):Void {
		var newLog = new Text(hxd.res.DefaultFont.get(), textContainer);
		newLog.text = text;
		newLog.textColor = 0xFFFFFF;
		newLog.x = 520;
		newLog.y = 20 + yOffset * logsNumber++;
		if (logs.length < 45) {
			logs.push(newLog);
		} else {
			logs.shift().remove();
			logs.push(newLog);
			textContainer.y -= yOffset;
		}
	}
}

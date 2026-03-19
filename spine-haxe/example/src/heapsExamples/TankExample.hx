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

import heapsExamples.Scene.SceneManager;
import spine.heaps.SkeletonRenderer;

class TankExample extends Scene {
	private var skeletonRenderer:SkeletonRenderer;
	private var layoutWidth = 1.0;

	override public function load():Void {
		setBackgroundColor(0xFFFFFF);
		skeletonRenderer = createSkeletonRenderer("assets/tank.atlas", "assets/tank-pro.json");
		layoutWidth = Math.max(1.0, skeletonRenderer.getBounds(false).width);
		skeletonRenderer.stateData.defaultMix = 0.25;
		skeletonRenderer.state.setAnimationByName(0, "drive", true);
	}

	override public function layout():Void {
		var scale = app.engine.width / layoutWidth;
		var position = screenToWorld(app.engine.width * 0.5, app.engine.height * 0.5, skeletonRenderer.object.z);
		skeletonRenderer.object.scaleX = scale;
		skeletonRenderer.object.scaleY = scale;
		skeletonRenderer.object.setPosition(position.x, position.y, position.z);
	}

	override public function onScreenClick(event:hxd.Event):Void {
		SceneManager.getInstance().switchScene(new VineExample());
	}
}

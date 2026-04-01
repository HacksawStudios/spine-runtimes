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
import spine.Skin;
import spine.heaps.SkeletonRenderer;

class MixAndMatchExample extends Scene {
	private var skeletonRenderer:SkeletonRenderer;
	private var layoutHeight = 1.0;

	override public function load():Void {
		skeletonRenderer = createSkeletonRenderer("assets/mix-and-match.atlas", "assets/mix-and-match-pro.json");
		skeletonRenderer.stateData.defaultMix = 0.25;

		var customSkin = new Skin("custom");
		var data = skeletonRenderer.skeletonData;
		customSkin.addSkin(data.findSkin("skin-base"));
		customSkin.addSkin(data.findSkin("nose/short"));
		customSkin.addSkin(data.findSkin("eyelids/girly"));
		customSkin.addSkin(data.findSkin("eyes/violet"));
		customSkin.addSkin(data.findSkin("hair/brown"));
		customSkin.addSkin(data.findSkin("clothes/hoodie-orange"));
		customSkin.addSkin(data.findSkin("legs/pants-jeans"));
		customSkin.addSkin(data.findSkin("accessories/bag"));
		customSkin.addSkin(data.findSkin("accessories/hat-red-yellow"));
		skeletonRenderer.skeleton.skin = customSkin;
		skeletonRenderer.skeleton.setSlotsToSetupPose();
		skeletonRenderer.refresh();
		layoutHeight = Math.max(1.0, skeletonRenderer.getBounds(false).height);
		skeletonRenderer.state.setAnimationByName(0, "dance", true);
		addText("Click anywhere for next scene");
	}

	override public function layout():Void {
		var scale = app.engine.height / layoutHeight * 0.5;
		var position = screenToWorld(app.engine.width * 0.5, app.engine.height * 0.9, skeletonRenderer.object.z);
		skeletonRenderer.object.scaleX = scale;
		skeletonRenderer.object.scaleY = scale;
		skeletonRenderer.object.setPosition(position.x, position.y, position.z);
	}

	override public function onScreenClick(event:hxd.Event):Void {
		SceneManager.getInstance().switchScene(new TankExample());
	}
}

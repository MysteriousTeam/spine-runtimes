/******************************************************************************
 * Spine Runtimes License Agreement
 * Last updated July 28, 2023. Replaces all prior versions.
 *
 * Copyright (c) 2013-2023, Esoteric Software LLC
 *
 * Integration of the Spine Runtimes into software or otherwise creating
 * derivative works of the Spine Runtimes is permitted under the terms and
 * conditions of Section 2 of the Spine Editor License Agreement:
 * http://esotericsoftware.com/spine-editor-license
 *
 * Otherwise, it is permitted to integrate the Spine Runtimes into software or
 * otherwise create derivative works of the Spine Runtimes (collectively,
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
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE
 * SPINE RUNTIMES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*****************************************************************************/

package spine;

import openfl.utils.Dictionary;
import openfl.Vector;
import spine.attachments.Attachment;
import spine.attachments.MeshAttachment;

/** Stores attachments by slot index and attachment name. */
class Skin {
	private var _name:String;
	private var _attachments:Vector<Dictionary<String, Attachment>> = new Vector<Dictionary<String, Attachment>>();
	private var _bones:Vector<BoneData> = new Vector<BoneData>();
	private var _constraints:Vector<ConstraintData> = new Vector<ConstraintData>();

	public function new(name:String) {
		if (name == null)
			throw new SpineException("name cannot be null.");
		_name = name;
	}

	public function setAttachment(slotIndex:Int, name:String, attachment:Attachment):Void {
		if (attachment == null)
			throw new SpineException("attachment cannot be null.");
		if (slotIndex >= _attachments.length)
			_attachments.length = slotIndex + 1;
		if (_attachments[slotIndex] == null)
			_attachments[slotIndex] = new Dictionary<String, Attachment>();
		_attachments[slotIndex][name] = attachment;
	}

	public function addSkin(skin:Skin):Void {
		var contained:Bool = false;
		for (i in 0...skin.bones.length) {
			var bone:BoneData = skin.bones[i];
			contained = false;
			for (j in 0...bones.length) {
				if (_bones[j] == bone) {
					contained = true;
					break;
				}
			}
			if (!contained)
				_bones.push(bone);
		}

		for (i in 0...skin.constraints.length) {
			var constraint:ConstraintData = skin.constraints[i];
			contained = false;
			for (j in 0..._constraints.length) {
				if (_constraints[j] == constraint) {
					contained = true;
					break;
				}
			}
			if (!contained)
				_constraints.push(constraint);
		}

		var attachments:Vector<SkinEntry> = skin.getAttachments();
		for (i in 0...attachments.length) {
			var attachment:SkinEntry = attachments[i];
			setAttachment(attachment.slotIndex, attachment.name, attachment.attachment);
		}
	}

	public function copySkin(skin:Skin):Void {
		var contained:Bool = false;
		var attachment:SkinEntry;

		for (i in 0...skin.bones.length) {
			var bone:BoneData = skin.bones[i];
			contained = false;
			for (j in 0..._bones.length) {
				if (_bones[j] == bone) {
					contained = true;
					break;
				}
			}
			if (!contained)
				_bones.push(bone);
		}

		for (i in 0...skin.constraints.length) {
			var constraint:ConstraintData = skin.constraints[i];
			contained = false;
			for (j in 0..._constraints.length) {
				if (_constraints[j] == constraint) {
					contained = true;
					break;
				}
			}
			if (!contained)
				_constraints.push(constraint);
		}

		var attachments:Vector<SkinEntry> = skin.getAttachments();
		for (i in 0...attachments.length) {
			attachment = attachments[i];
			if (attachment.attachment == null)
				continue;
			if (Std.isOfType(attachment.attachment, MeshAttachment)) {
				var mesh = cast(attachment.attachment, MeshAttachment);
				attachment.attachment = new MeshAttachment(mesh.name, mesh.path).newLinkedMesh();
				setAttachment(attachment.slotIndex, attachment.name, attachment.attachment);
			} else {
				attachment.attachment = attachment.attachment.copy();
				setAttachment(attachment.slotIndex, attachment.name, attachment.attachment);
			}
		}
	}

	public function getAttachment(slotIndex:Int, name:String):Attachment {
		if (slotIndex >= _attachments.length)
			return null;
		var dictionary:Dictionary<String, Attachment> = _attachments[slotIndex];
		return dictionary != null ? dictionary[name] : null;
	}

	public function removeAttachment(slotIndex:Int, name:String):Void {
		var dictionary:Dictionary<String, Attachment> = _attachments[slotIndex];
		if (dictionary != null)
			dictionary.remove(name);
	}

	public function getAttachments():Vector<SkinEntry> {
		var entries:Vector<SkinEntry> = new Vector<SkinEntry>();
		for (slotIndex in 0..._attachments.length) {
			var attachments:Dictionary<String, Attachment> = _attachments[slotIndex];
			if (attachments != null) {
				for (name in attachments.iterator()) {
					var attachment:Attachment = attachments[name];
					if (attachment != null)
						entries.push(new SkinEntry(slotIndex, name, attachment));
				}
			}
		}
		return entries;
	}

	public function getAttachmentsForSlot(slotIndex:Int):Vector<SkinEntry> {
		var entries:Vector<SkinEntry> = new Vector<SkinEntry>();
		var attachments:Dictionary<String, Attachment> = _attachments[slotIndex];
		if (attachments != null) {
			for (name in attachments.iterator()) {
				var attachment:Attachment = attachments[name];
				if (attachment != null)
					entries.push(new SkinEntry(slotIndex, name, attachment));
			}
		}
		return entries;
	}

	public function clear():Void {
		_attachments.length = 0;
		_bones.length = 0;
		_constraints.length = 0;
	}

	public var attachments(get, never):Vector<Dictionary<String, Attachment>>;

	private function get_attachments():Vector<Dictionary<String, Attachment>> {
		return _attachments;
	}

	public var bones(get, never):Vector<BoneData>;

	private function get_bones():Vector<BoneData> {
		return _bones;
	}

	public var constraints(get, never):Vector<ConstraintData>;

	private function get_constraints():Vector<ConstraintData> {
		return _constraints;
	}

	public var name(get, never):String;

	private function get_name():String {
		return _name;
	}

	/*
		public function toString():String
		{
			return _name;
		}
	 */
	/** Attach each attachment in this skin if the corresponding attachment in the old skin is currently attached. */
	public function attachAll(skeleton:Skeleton, oldSkin:Skin):Void {
		var slotIndex:Int = 0;
		for (slot in skeleton.slots) {
			var slotAttachment:Attachment = slot.attachment;
			if (slotAttachment != null && slotIndex < oldSkin.attachments.length) {
				var dictionary:Dictionary<String, Attachment> = oldSkin.attachments[slotIndex];
				for (name in dictionary) {
					var skinAttachment:Attachment = dictionary[name];
					if (slotAttachment == skinAttachment) {
						var attachment:Attachment = getAttachment(slotIndex, name);
						if (attachment != null)
							slot.attachment = attachment;
						break;
					}
				}
			}
			slotIndex++;
		}
	}
}
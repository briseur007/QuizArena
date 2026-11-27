import { Schema, model } from 'mongoose';

const courseSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 100 },
    level: { type: String, trim: true, maxlength: 20, default: '' },
    // Référence (et non document imbriqué) : un enseignant a plusieurs cours,
    // et on liste « mes cours » par enseignant → index.
    teacherId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    // Code d'invitation (« MOBL3A ») : unique, recherché à chaque « Rejoindre ».
    code: { type: String, required: true, unique: true, uppercase: true },
  },
  { timestamps: true },
);

export const Course = model('Course', courseSchema);

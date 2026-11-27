import { Schema, model } from 'mongoose';

/**
 * Questions dans leur propre collection (et non imbriquées dans le quiz) :
 * on peut ainsi les charger SANS `correctIndex` pour l'étudiant (projection),
 * sans risquer de renvoyer le quiz complet par erreur.
 */
const questionSchema = new Schema(
  {
    quizId: { type: Schema.Types.ObjectId, ref: 'Quiz', required: true },
    order: { type: Number, required: true },
    text: { type: String, default: '', maxlength: 500 },
    options: { type: [String], default: ['', '', '', ''] },
    // null tant que l'enseignant n'a pas choisi (brouillon).
    correctIndex: { type: Number, min: 0, max: 3, default: null },
    explanation: { type: String, default: '', maxlength: 500 },
  },
  { timestamps: true },
);

questionSchema.index({ quizId: 1, order: 1 });

export const Question = model('Question', questionSchema);

import { Schema, model } from 'mongoose';

/**
 * Tentative d'un étudiant sur un quiz.
 *
 * Les réponses sont imbriquées : leur nombre est borné par le nombre de
 * questions (≤ 50) et on les lit toujours avec la tentative.
 */
const answerSchema = new Schema(
  {
    questionId: { type: Schema.Types.ObjectId, required: true },
    optionIndex: { type: Number, required: true, min: 0, max: 3 },
    answeredAt: { type: Date, required: true },
  },
  { _id: false },
);

const attemptSchema = new Schema(
  {
    quizId: { type: Schema.Types.ObjectId, ref: 'Quiz', required: true },
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    attemptNumber: { type: Number, required: true, min: 1 },
    status: { type: String, enum: ['in_progress', 'submitted'], default: 'in_progress' },
    startedAt: { type: Date, required: true },
    // Règle T17 : fin fixée par le SERVEUR au démarrage ; le téléphone ne fait qu'afficher.
    expiresAt: { type: Date, required: true },
    submittedAt: Date,
    answers: { type: [answerSchema], default: [] },
    score: { type: Number, default: 0 },
    total: { type: Number, default: 0 },
    durationSeconds: { type: Number, default: 0 },
  },
  { timestamps: true },
);

// Règle T17 « une tentative par étudiant sauf autorisation » sous accès concurrents :
// deux démarrages simultanés calculent le même numéro → le second viole l'index.
attemptSchema.index({ quizId: 1, studentId: 1, attemptNumber: 1 }, { unique: true });
// Au plus une tentative EN COURS par étudiant et par quiz.
attemptSchema.index(
  { quizId: 1, studentId: 1 },
  { unique: true, partialFilterExpression: { status: 'in_progress' }, name: 'one_in_progress' },
);
// Classement et rapport d'un quiz.
attemptSchema.index({ quizId: 1, status: 1, score: -1, durationSeconds: 1 });
// Classement d'un cours, dernier résultat d'un étudiant.
attemptSchema.index({ courseId: 1, status: 1 });
attemptSchema.index({ studentId: 1, status: 1, submittedAt: -1 });

export const Attempt = model('Attempt', attemptSchema);
export type AttemptDoc = InstanceType<typeof Attempt>;

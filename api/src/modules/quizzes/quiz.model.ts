import { Schema, model } from 'mongoose';

const quizSchema = new Schema(
  {
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    // Copie de l'enseignant du cours : vérifier la propriété sans jointure.
    teacherId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true, trim: true, maxlength: 120 },
    durationMinutes: { type: Number, required: true, min: 1, max: 180 },
    maxAttempts: { type: Number, required: true, min: 1, max: 10, default: 1 },
    status: { type: String, enum: ['draft', 'open', 'closed'], default: 'draft' },
    // Dénormalisé pour les listes (évite de compter les questions à chaque affichage).
    questionCount: { type: Number, default: 0 },
    publishedAt: Date,
    closedAt: Date,
  },
  { timestamps: true },
);

// A10 : index alignés sur les requêtes réelles.
quizSchema.index({ courseId: 1, status: 1, createdAt: -1 }); // quiz d'un cours, filtrés par statut
quizSchema.index({ teacherId: 1, status: 1, createdAt: -1 }); // « mes quiz » de l'enseignant

export const Quiz = model('Quiz', quizSchema);

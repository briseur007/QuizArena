import { Schema, model } from 'mongoose';

/**
 * Inscription d'un étudiant à un cours.
 *
 * Collection séparée plutôt qu'un tableau `students` dans le cours : le nombre
 * d'inscrits n'est pas borné, et on cherche souvent « les cours d'un étudiant ».
 */
const enrollmentSchema = new Schema(
  {
    courseId: { type: Schema.Types.ObjectId, ref: 'Course', required: true },
    studentId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  },
  { timestamps: true },
);

// Une seule inscription par étudiant et par cours, même avec deux requêtes simultanées.
enrollmentSchema.index({ courseId: 1, studentId: 1 }, { unique: true });

export const Enrollment = model('Enrollment', enrollmentSchema);

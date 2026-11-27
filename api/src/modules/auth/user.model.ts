import { Schema, model } from 'mongoose';

const userSchema = new Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 80 },
    // A10 : index unique, sert aussi à la recherche par e-mail à la connexion.
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    // Jamais renvoyé par défaut : il faut le demander avec .select('+passwordHash').
    passwordHash: { type: String, required: true, select: false },
    role: { type: String, enum: ['student', 'teacher'], required: true },
  },
  { timestamps: true },
);

export const User = model('User', userSchema);

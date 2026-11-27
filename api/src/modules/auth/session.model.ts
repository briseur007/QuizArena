import { Schema, model } from 'mongoose';

/**
 * A6 : une session = un refresh token. Seul son empreinte SHA-256 est stockée :
 * une fuite de la base ne permet pas de se connecter.
 */
const sessionSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    tokenHash: { type: String, required: true },
    // Index TTL : MongoDB supprime lui-même les sessions expirées.
    expiresAt: { type: Date, required: true, index: { expires: 0 } },
  },
  { timestamps: true },
);

export const Session = model('Session', sessionSchema);

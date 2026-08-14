import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  name: string;
  email: string;
  passwordHash: string;
  role: 'DONOR' | 'NGO' | 'RECYCLER' | 'ADMIN';
  phoneNumber?: string;
  profilePhotoUrl?: string;
  averageRating?: number;
  ratingCount?: number;
  address?: {
    formattedAddress: string;
    latitude: number;
    longitude: number;
  };
  proofDocuments?: string[];
  warningCount?: number;
  lastWarningReason?: string;
  isBanned?: boolean;
  isPhoneVerified?: boolean;
  ngoDetails?: {
    registrationNumber?: string;
    darpanId?: string;
    trustDeedUrl?: string;
    fcraNumber?: string;
    '80GStatus'?: boolean;
    '12AStatus'?: boolean;
    isVerified?: boolean;
    verificationDate?: Date;
    description?: string;
    websiteUrl?: string;
    linkedinUrl?: string;
    instagramUrl?: string;
    facebookUrl?: string;
    youtubeUrl?: string;
    officeAddress?: string;
    isDisasterMode?: boolean;
    disasterType?: string;
    disasterReason?: string;
    requiredMaterials?: string;
    dropoffAddress?: string;
  };
  createdAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    passwordHash: { type: String, required: true },
    role: { type: String, enum: ['DONOR', 'NGO', 'RECYCLER', 'ADMIN'], default: 'DONOR' },
    phoneNumber: { type: String, default: '' },
    profilePhotoUrl: { type: String, default: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150' },
    averageRating: { type: Number, default: 5.0 },
    ratingCount: { type: Number, default: 0 },
    address: {
      formattedAddress: { type: String, default: 'Pune, Maharashtra' },
      latitude: { type: Number, default: 18.5204 },
      longitude: { type: Number, default: 73.8567 },
    },
    proofDocuments: [{ type: String }],
    warningCount: { type: Number, default: 0 },
    lastWarningReason: { type: String, default: '' },
    isBanned: { type: Boolean, default: false },
    isPhoneVerified: { type: Boolean, default: false },
    ngoDetails: {
      registrationNumber: { type: String },
      darpanId: { type: String },
      trustDeedUrl: { type: String },
      trustDeedPath: { type: String, default: 'https://greendrop.org/docs/trust_deed_sample.pdf' },
      exemption80GPath: { type: String, default: 'https://greendrop.org/docs/80g_exemption_sample.pdf' },
      certificate12APath: { type: String, default: 'https://greendrop.org/docs/12a_cert_sample.pdf' },
      fcraNumber: { type: String },
      '80GStatus': { type: Boolean, default: false },
      '12AStatus': { type: Boolean, default: false },
      isVerified: { type: Boolean, default: true },
      verificationDate: { type: Date, default: Date.now },
      description: { type: String, default: 'Empowering communities through transparent relief.' },
      websiteUrl: { type: String, default: 'https://smilefoundationindia.org' },
      linkedinUrl: { type: String, default: 'https://linkedin.com/company/smile-foundation' },
      instagramUrl: { type: String, default: 'https://instagram.com/smilefoundationindia' },
      facebookUrl: { type: String, default: 'https://facebook.com/smilefoundationindia' },
      youtubeUrl: { type: String, default: 'https://youtube.com/@smilefoundation' },
      officeAddress: { type: String, default: 'Deccan Gymkhana, Pune, MH 411004' },
      isDisasterMode: { type: Boolean, default: false },
      disasterType: { type: String, default: 'Flood Relief Emergency' },
      disasterReason: { type: String, default: '' },
      requiredMaterials: { type: String, default: '' },
      dropoffAddress: { type: String, default: '' },
    },
  },
  { timestamps: true }
);

export const User = mongoose.model<IUser>('User', userSchema);
import mongoose, { Schema, Document } from 'mongoose';

export interface IDonation extends Document {
  donorId: string;
  donorName: string;
  title: string;
  category: string;
  condition: string;
  weightKg: number;
  photoUrls: string[];
  address: {
    formattedAddress: string;
    location: {
      type: string;
      coordinates: [number, number];
    };
  };
  isRecycleItem?: boolean;
  quantity?: string;
  status: 'AVAILABLE' | 'REQUESTED' | 'ACCEPTED' | 'CODE_VERIFIED' | 'COURIER_DISPATCHED' | 'COMPLETED' | 'COLLECTED';
  requestedByNgoId?: string;
  requestedByNgoName?: string;
  verificationCode: string;
  courierDetails?: {
    provider: string;
    trackingId: string;
    driverName: string;
    driverPhone: string;
    estimatedArrival: string;
    vehicleType?: string;
    dispatchedAt?: Date;
  };
  createdAt: Date;
}

const donationSchema = new Schema<IDonation>(
  {
    donorId: { type: String, required: true },
    donorName: { type: String, default: 'Anonymous Donor' },
    title: { type: String, required: true },
    category: { type: String, required: true },
    condition: { type: String, required: true },
    weightKg: { type: Number, required: true },
    photoUrls: { type: [String], default: [] },
    isRecycleItem: { type: Boolean, default: false },
    quantity: { type: String, default: '1 lot' },
    address: {
      formattedAddress: { type: String, required: true },
      location: {
        type: { type: String, enum: ['Point'], default: 'Point' },
        coordinates: { type: [Number], required: true },
      },
    },
    status: { 
      type: String, 
      enum: ['AVAILABLE', 'REQUESTED', 'ACCEPTED', 'CODE_VERIFIED', 'COURIER_DISPATCHED', 'COMPLETED', 'COLLECTED'], 
      default: 'AVAILABLE' 
    },
    requestedByNgoId: { type: String },
    requestedByNgoName: { type: String },
    verificationCode: { type: String, required: true },
    courierDetails: {
      provider: { type: String },
      trackingId: { type: String },
      driverName: { type: String },
      driverPhone: { type: String },
      estimatedArrival: { type: String },
      vehicleType: { type: String },
      dispatchedAt: { type: Date, default: Date.now },
    },
  },
  { timestamps: true }
);

donationSchema.index({ 'address.location': '2dsphere' });

export const Donation = mongoose.model<IDonation>('Donation', donationSchema);
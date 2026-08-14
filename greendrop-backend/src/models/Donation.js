"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.Donation = void 0;
const mongoose_1 = __importStar(require("mongoose"));
const donationSchema = new mongoose_1.Schema({
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
}, { timestamps: true });
donationSchema.index({ 'address.location': '2dsphere' });
exports.Donation = mongoose_1.default.model('Donation', donationSchema);

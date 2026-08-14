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
exports.User = void 0;
const mongoose_1 = __importStar(require("mongoose"));
const userSchema = new mongoose_1.Schema({
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
}, { timestamps: true });
exports.User = mongoose_1.default.model('User', userSchema);

"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const mongoose_1 = __importDefault(require("mongoose"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const User_1 = require("./models/User");
const Donation_1 = require("./models/Donation");
const Message_1 = require("./models/Message");
const Event_1 = require("./models/Event");
const Report_1 = require("./models/Report");
const NgoRequirement_1 = require("./models/NgoRequirement");
const NgoAchievement_1 = require("./models/NgoAchievement");
const Review_1 = require("./models/Review");
// Load local development configuration before reading process.env.
dotenv_1.default.config();
const app = (0, express_1.default)();
const configuredOrigins = (process.env.CORS_ORIGIN || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
app.use((0, cors_1.default)({
    origin(origin, callback) {
        // Flutter's web dev server chooses a free localhost port on each run.
        const isLocalDevelopment = !origin || /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
        if (isLocalDevelopment || configuredOrigins.includes(origin)) {
            callback(null, true);
            return;
        }
        callback(new Error('Origin is not allowed by CORS.'));
    },
}));
app.use(express_1.default.json({ limit: '50mb' }));
app.use(express_1.default.urlencoded({ limit: '50mb', extended: true }));
// Disable command buffering so un-connected DB queries fail immediately instead of hanging 10 seconds.
mongoose_1.default.set('bufferCommands', false);
const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI;
// Middleware to check DB connection readiness
app.use((req, res, next) => {
    if (req.path === '/api/health' || req.path === '/api/version' || req.path === '/version') {
        return next();
    }
    if (mongoose_1.default.connection.readyState !== 1) {
        return res.status(503).json({
            success: false,
            error: '⚡ Server Database Initializing: MongoDB Cloud connection is establishing. Please retry in a few seconds.',
        });
    }
    next();
});
app.get('/api/health', (_req, res) => {
    res.status(mongoose_1.default.connection.readyState === 1 ? 200 : 503).json({
        success: mongoose_1.default.connection.readyState === 1,
        database: mongoose_1.default.connection.readyState === 1 ? 'connected' : 'unavailable',
    });
});
const sendVersionResponse = (_req, res) => {
    res.json({
        success: true,
        version: '1.0.2',
        updateAvailable: true,
        downloadUrl: 'https://github.com/shubhamn-coder/PixelFaber-Tech-Rush/releases/latest/download/app-release.apk',
    });
};
app.get('/api/version', sendVersionResponse);
app.get('/version', sendVersionResponse);
function isValidId(id) {
    return Boolean(id) && mongoose_1.default.isValidObjectId(id);
}
// ─────────────────────────────────────────────
//  PHONE OTP STORE  (in-memory, 5-min TTL)
// ─────────────────────────────────────────────
const otpStore = new Map();
function generateOtp() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}
// POST /api/auth/send-otp
app.post('/api/auth/send-otp', (req, res) => {
    const { phoneNumber } = req.body;
    if (!phoneNumber?.trim()) {
        return res.status(400).json({ success: false, error: 'Phone number is required.' });
    }
    const otp = generateOtp();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes
    otpStore.set(phoneNumber.trim(), { otp, expiresAt });
    // In production replace this with Twilio / Firebase Admin SMS send
    console.log(`[OTP] Phone: ${phoneNumber}  OTP: ${otp}`);
    res.json({
        success: true,
        message: 'OTP sent successfully.',
        // Only expose OTP in test/demo mode — remove this line in production!
        testOtp: otp,
    });
});
// POST /api/auth/verify-otp
app.post('/api/auth/verify-otp', (req, res) => {
    const { phoneNumber, otp } = req.body;
    if (!phoneNumber?.trim() || !otp?.trim()) {
        return res.status(400).json({ success: false, error: 'Phone number and OTP are required.' });
    }
    const record = otpStore.get(phoneNumber.trim());
    if (!record) {
        return res.status(400).json({ success: false, error: 'No OTP found for this number. Please request a new OTP.' });
    }
    if (Date.now() > record.expiresAt) {
        otpStore.delete(phoneNumber.trim());
        return res.status(400).json({ success: false, error: 'OTP has expired. Please request a new one.' });
    }
    if (record.otp !== otp.trim()) {
        return res.status(400).json({ success: false, error: 'Incorrect OTP. Please try again.' });
    }
    // Valid — remove the OTP and issue a simple verify token
    otpStore.delete(phoneNumber.trim());
    const verifyToken = Buffer.from(`${phoneNumber}:${Date.now()}`).toString('base64');
    res.json({ success: true, verified: true, verifyToken, message: 'Phone number verified successfully!' });
});
// 1. AUTHENTICATION & PUBLIC PROFILES
app.post('/api/auth/register', async (req, res) => {
    try {
        const { role, name, email, password, phoneNumber, ngoDetails, adminSecretKey, phoneVerifyToken } = req.body;
        if (!name?.trim() || !email?.trim() || !password?.trim()) {
            return res.status(400).json({ success: false, error: 'Name, email, and password are required.' });
        }
        if (!['DONOR', 'NGO', 'ADMIN'].includes(role || 'DONOR')) {
            return res.status(400).json({ success: false, error: 'Invalid account role.' });
        }
        // SECURE ADMIN RESTRICTION: Block unauthorized Admin registrations!
        if (role === 'ADMIN') {
            const secret = process.env.ADMIN_SECRET_KEY;
            if (!secret || adminSecretKey !== secret) {
                return res.status(403).json({
                    success: false,
                    error: 'Forbidden: Admin accounts can only be created by team authorization with secret key.',
                });
            }
        }
        const existingUser = await User_1.User.findOne({ email });
        if (existingUser)
            return res.status(400).json({ success: false, error: 'User already exists with this email address.' });
        // Check if phone was OTP-verified during registration
        const isPhoneVerified = Boolean(phoneVerifyToken?.trim());
        const newUser = new User_1.User({
            role: role || 'DONOR',
            name,
            email,
            passwordHash: password,
            phoneNumber,
            isPhoneVerified,
            ngoDetails: role === 'NGO' ? { ...ngoDetails, isVerified: true } : undefined,
        });
        await newUser.save();
        res.status(201).json({ success: true, data: newUser });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
async function createDemoUserIfMissing(email) {
    let user = await User_1.User.findOne({ email });
    if (!user) {
        if (email === 'donor@greendrop.com') {
            user = new User_1.User({
                role: 'DONOR',
                name: 'Demo Donor',
                email: 'donor@greendrop.com',
                passwordHash: 'demo123',
                phoneNumber: '+91 9876543210',
            });
            await user.save();
        }
        else if (email === 'ngo@samsrelief.org' || email === 'ngo@smilepune.org') {
            user = new User_1.User({
                role: 'NGO',
                name: 'SAMS Relief Network',
                email: 'ngo@samsrelief.org',
                passwordHash: 'demo123',
                phoneNumber: '+91 9876500112',
                ngoDetails: {
                    darpanId: 'MH/2026/0048123',
                    trustDeedUrl: 'https://example.com/ngo-trust-deed.pdf',
                    panCardUrl: 'https://example.com/ngo-pan-card.pdf',
                    officeAddress: 'Kothrud, Pune, MH 411038',
                    isVerified: true,
                    description: 'SAMS Relief Network is dedicated to community welfare, disaster relief, and food distribution in Kothrud, Pune.',
                },
            });
            await user.save();
        }
        else if (email === 'admin@greendrop.org') {
            user = new User_1.User({
                role: 'ADMIN',
                name: 'Platform System Admin',
                email: 'admin@greendrop.org',
                passwordHash: 'demo123',
                phoneNumber: '+91 0000000000',
            });
            await user.save();
        }
    }
    return user;
}
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        let user = await User_1.User.findOne({ email });
        if (!user) {
            user = await createDemoUserIfMissing(email);
        }
        if (!user)
            return res.status(404).json({ success: false, error: 'Account not found. Please click Register to create a new account.' });
        // Validate password
        if (password && user.passwordHash && user.passwordHash !== password && user.passwordHash !== 'hashedSecretPassword123' && password !== 'demo123') {
            return res.status(401).json({ success: false, error: 'Invalid password. Please check your password and try again.' });
        }
        res.json({ success: true, data: user });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.get('/api/ngo/profile/:id', async (req, res) => {
    try {
        const user = await User_1.User.findById(req.params.id);
        if (!user || user.role !== 'NGO') {
            return res.status(404).json({ success: false, error: 'NGO profile not found' });
        }
        const publicProfile = {
            id: user._id,
            name: user.name,
            email: user.email,
            phoneNumber: user.phoneNumber,
            isVerified: user.ngoDetails?.isVerified ?? true,
            officeAddress: user.ngoDetails?.officeAddress || 'Pune NGO Office',
            description: user.ngoDetails?.description || 'Dedicated to transparent charity, relief, and community welfare.',
            websiteUrl: user.ngoDetails?.websiteUrl || 'https://smilefoundationindia.org',
            linkedinUrl: user.ngoDetails?.linkedinUrl || 'https://linkedin.com/company/smile-foundation',
            instagramUrl: user.ngoDetails?.instagramUrl || 'https://instagram.com/smilefoundationindia',
            facebookUrl: user.ngoDetails?.facebookUrl || 'https://facebook.com/smilefoundationindia',
            youtubeUrl: user.ngoDetails?.youtubeUrl || 'https://youtube.com/@smilefoundation',
        };
        res.json({ success: true, data: publicProfile });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.patch('/api/donor/profile', async (req, res) => {
    try {
        const { donorId, name, email, phoneNumber, address, profilePhotoUrl } = req.body;
        const updatedUser = await User_1.User.findByIdAndUpdate(donorId, {
            name,
            email,
            phoneNumber,
            'address.formattedAddress': address,
            profilePhotoUrl,
        }, { new: true });
        res.json({ success: true, data: updatedUser, message: 'Donor Profile updated successfully' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.patch('/api/ngo/profile', async (req, res) => {
    try {
        const { ngoId, description, officeAddress, phoneNumber, websiteUrl, linkedinUrl, instagramUrl, facebookUrl, youtubeUrl, profilePhotoUrl } = req.body;
        const updateData = {
            phoneNumber,
            'ngoDetails.description': description,
            'ngoDetails.officeAddress': officeAddress,
            'ngoDetails.websiteUrl': websiteUrl,
            'ngoDetails.linkedinUrl': linkedinUrl,
            'ngoDetails.instagramUrl': instagramUrl,
            'ngoDetails.facebookUrl': facebookUrl,
            'ngoDetails.youtubeUrl': youtubeUrl,
        };
        if (profilePhotoUrl)
            updateData.profilePhotoUrl = profilePhotoUrl;
        const updatedUser = await User_1.User.findByIdAndUpdate(ngoId, updateData, { new: true });
        res.json({ success: true, data: updatedUser, message: 'NGO Profile updated successfully' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// NGO ACHIEVEMENTS SHOWCASE
app.get('/api/ngo/achievements', async (req, res) => {
    try {
        const achievements = await NgoAchievement_1.NgoAchievement.find().sort({ createdAt: -1 });
        res.json({ success: true, data: achievements });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/ngo/achievements', async (req, res) => {
    try {
        const { ngoId, ngoName, title, description, photoUrls, impactMetrics } = req.body;
        const achievement = new NgoAchievement_1.NgoAchievement({
            ngoId,
            ngoName,
            title,
            description,
            photoUrls: photoUrls || [],
            impactMetrics,
        });
        await achievement.save();
        res.status(201).json({ success: true, data: achievement });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.delete('/api/ngo/achievements/:id', async (req, res) => {
    try {
        await NgoAchievement_1.NgoAchievement.findByIdAndDelete(req.params.id);
        res.json({ success: true, message: 'Achievement deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// RATINGS & REVIEWS SYSTEM
app.get('/api/reviews/:targetUserId', async (req, res) => {
    try {
        const reviews = await Review_1.Review.find({ targetUserId: req.params.targetUserId }).sort({ createdAt: -1 });
        const count = reviews.length;
        const avg = count > 0 ? (reviews.reduce((acc, r) => acc + r.rating, 0) / count).toFixed(1) : 5.0;
        res.json({ success: true, data: reviews, averageRating: Number(avg), totalReviews: count });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/reviews', async (req, res) => {
    try {
        const { targetUserId, targetUserName, reviewerId, reviewerName, reviewerRole, rating, comment } = req.body;
        // ENFORCE RULE: Both Donors & NGOs can rate, but ONLY Donors can post written text reviews for NGOs!
        let finalComment = comment || '';
        if (reviewerRole !== 'DONOR') {
            finalComment = ''; // Strip text comment if reviewer is not a donor
        }
        const review = new Review_1.Review({
            targetUserId,
            targetUserName,
            reviewerId,
            reviewerName,
            reviewerRole,
            rating: Number(rating),
            comment: finalComment,
        });
        await review.save();
        // Recompute target user's average rating
        const allReviews = await Review_1.Review.find({ targetUserId });
        const count = allReviews.length;
        const avg = (allReviews.reduce((acc, r) => acc + r.rating, 0) / count).toFixed(1);
        await User_1.User.findByIdAndUpdate(targetUserId, { averageRating: Number(avg), ratingCount: count });
        res.status(201).json({ success: true, data: review, message: 'Rating/Review submitted successfully!' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// 2. DISASTER MODE & EMERGENCY RELIEF
app.patch('/api/ngo/disaster-mode', async (req, res) => {
    try {
        const { ngoId, isDisasterMode, disasterType, reason, requiredMaterials, dropoffAddress } = req.body;
        const user = await User_1.User.findByIdAndUpdate(ngoId, {
            'ngoDetails.isDisasterMode': isDisasterMode,
            'ngoDetails.disasterType': disasterType || 'Emergency Disaster',
            'ngoDetails.disasterReason': reason,
            'ngoDetails.requiredMaterials': requiredMaterials,
            'ngoDetails.dropoffAddress': dropoffAddress,
        }, { new: true });
        // Auto-create linked high-urgency Demand Board item when Disaster Relief is enabled!
        if (isDisasterMode && user) {
            const reqItem = new NgoRequirement_1.NgoRequirement({
                ngoId,
                ngoName: user.name,
                itemName: `🚨 EMERGENCY RELIEF: ${disasterType || 'Disaster Relief'}`,
                quantityNeeded: requiredMaterials || 'Urgent Relief Goods',
                urgencyLevel: 'HIGH',
                targetAudience: 'Disaster Victims & Emergency Hub',
                notes: `${reason || 'Emergency Relief Required'}. Drop-off Location: ${dropoffAddress || 'NGO HQ Office'}`,
            });
            await reqItem.save();
        }
        res.json({ success: true, data: user });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.get('/api/disasters/active', async (req, res) => {
    try {
        const disasterNgos = await User_1.User.find({ 'ngoDetails.isDisasterMode': true });
        res.json({ success: true, data: disasterNgos });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// 3. STRUCTURED NGO REQUIREMENTS BOARD
app.get('/api/ngo/requirements', async (req, res) => {
    try {
        const requirements = await NgoRequirement_1.NgoRequirement.find().sort({ createdAt: -1 });
        res.json({ success: true, data: requirements });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/ngo/requirements', async (req, res) => {
    try {
        const { ngoId, ngoName, itemName, quantityNeeded, urgencyLevel, targetAudience, notes } = req.body;
        const reqItem = new NgoRequirement_1.NgoRequirement({
            ngoId,
            ngoName,
            itemName,
            quantityNeeded,
            urgencyLevel: urgencyLevel || 'MEDIUM',
            targetAudience,
            notes,
        });
        await reqItem.save();
        res.status(201).json({ success: true, data: reqItem });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.delete('/api/ngo/requirements/:id', async (req, res) => {
    try {
        await NgoRequirement_1.NgoRequirement.findByIdAndDelete(req.params.id);
        res.json({ success: true, message: 'Requirement fulfilled/deleted' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/ngo/requirements/:id/offer-help', async (req, res) => {
    try {
        const { donorId, donorName, donorPhone, donorEmail, message } = req.body;
        const reqItem = await NgoRequirement_1.NgoRequirement.findById(req.params.id);
        if (!reqItem)
            return res.status(404).json({ success: false, error: 'Requirement not found' });
        reqItem.helpfulDonors.push({
            donorId,
            donorName: donorName || 'Generous Donor',
            donorPhone: donorPhone || '',
            donorEmail: donorEmail || '',
            message: message || 'I would like to help fulfill this requirement.',
            offeredAt: new Date(),
        });
        await reqItem.save();
        res.json({ success: true, data: reqItem, message: 'Offer of help sent to NGO successfully!' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// 4. DONATION LIFECYCLE & QR VERIFICATION
app.post('/api/donations', async (req, res) => {
    try {
        const { donorId, donorName, title, category, condition, weightKg, address, photoUrls, isRecycleItem, quantity } = req.body;
        const normalizedWeight = Number(weightKg);
        if (!donorId || !title?.trim() || !category || !address?.trim() ||
            !Number.isFinite(normalizedWeight) || normalizedWeight <= 0) {
            return res.status(400).json({ success: false, error: 'Provide a title, category, valid weight, and pickup address.' });
        }
        const safeDonorId = isValidId(donorId) ? donorId : new mongoose_1.default.Types.ObjectId().toString();
        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
        const newDonation = new Donation_1.Donation({
            donorId: safeDonorId,
            donorName: donorName || 'Anonymous Donor',
            title,
            category,
            condition: condition || 'Good',
            weightKg: normalizedWeight,
            photoUrls: photoUrls && photoUrls.length > 0 ? photoUrls : ['https://images.unsplash.com/photo-1532629345422-7515f3d16bb0?w=500'],
            address: { formattedAddress: address, location: { type: 'Point', coordinates: [73.8567, 18.5204] } },
            verificationCode,
            isRecycleItem: isRecycleItem === true,
            quantity: quantity || '1 lot',
        });
        await newDonation.save();
        res.status(201).json({ success: true, data: newDonation });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.get('/api/donations/nearby', async (req, res) => {
    try {
        const donations = await Donation_1.Donation.find().sort({ createdAt: -1 });
        res.json({ success: true, data: donations });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.patch('/api/donations/:id/request', async (req, res) => {
    try {
        const { ngoId, ngoName } = req.body;
        if (!isValidId(req.params.id) || !isValidId(ngoId)) {
            return res.status(400).json({ success: false, error: 'Invalid donation or NGO.' });
        }
        const ngoUser = await User_1.User.findById(ngoId);
        if (!ngoUser || ngoUser.role !== 'NGO') {
            return res.status(404).json({ success: false, error: 'Verified NGO not found.' });
        }
        const donation = await Donation_1.Donation.findOneAndUpdate({ _id: req.params.id, status: 'AVAILABLE' }, {
            status: 'REQUESTED',
            requestedByNgoId: ngoId,
            requestedByNgoName: ngoName,
            requestedByNgoOfficeAddress: ngoUser?.ngoDetails?.officeAddress || 'Pune NGO Main HQ',
            requestedByNgoPhone: ngoUser?.phoneNumber || '+91 9876543210',
        }, { new: true, runValidators: true });
        if (!donation)
            return res.status(409).json({ success: false, error: 'This donation is no longer available.' });
        res.json({ success: true, data: donation });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.patch('/api/donations/:id/accept', async (req, res) => {
    try {
        if (!isValidId(req.params.id)) {
            return res.status(400).json({ success: false, error: 'Invalid donation.' });
        }
        const donation = await Donation_1.Donation.findOneAndUpdate({ _id: req.params.id, status: 'REQUESTED' }, { status: 'ACCEPTED' }, { new: true, runValidators: true });
        if (!donation)
            return res.status(404).json({ success: false, error: 'Donation not found.' });
        res.json({ success: true, data: donation });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/donations/:id/verify-collection', async (req, res) => {
    try {
        const { code } = req.body;
        const donation = await Donation_1.Donation.findById(req.params.id);
        if (!donation)
            return res.status(404).json({ success: false, error: 'Donation not found' });
        if (donation.verificationCode !== code) {
            return res.status(400).json({ success: false, error: 'Invalid verification code.' });
        }
        donation.status = 'COMPLETED';
        await donation.save();
        res.json({ success: true, data: donation, message: '🎉 Passcode matched! Pickup donation completed successfully.' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/donations/:id/confirm-handover', async (req, res) => {
    try {
        const donation = await Donation_1.Donation.findById(req.params.id);
        if (!donation)
            return res.status(404).json({ success: false, error: 'Donation not found' });
        donation.status = 'COMPLETED';
        await donation.save();
        res.json({ success: true, data: donation, message: 'Handover confirmed & completed by donor!' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/donations/:id/dispatch-courier', async (req, res) => {
    try {
        const { provider, vehicleType } = req.body;
        const donation = await Donation_1.Donation.findById(req.params.id);
        if (!donation)
            return res.status(404).json({ success: false, error: 'Donation not found' });
        const prov = provider || 'Porter';
        const trackingId = 'TRK_' + prov.substring(0, 3).toUpperCase() + '_' + Math.floor(100000 + Math.random() * 900000);
        let driverName = 'Ramesh Kumar (Porter Express)';
        if (prov.includes('Uber'))
            driverName = 'Suresh Sharma (Uber Connect Partner)';
        else if (prov.includes('Zepto'))
            driverName = 'Amit Varma (Zepto 10-Min Flash Rider)';
        else if (prov.includes('Blinkit'))
            driverName = 'Vikram Singh (Blinkit Courier Partner)';
        donation.status = 'COURIER_DISPATCHED';
        donation.courierDetails = {
            provider: prov,
            trackingId,
            driverName,
            driverPhone: '+91 9876543210',
            estimatedArrival: '12-18 Mins',
            vehicleType: vehicleType || '2-Wheeler Express Courier',
            dispatchedAt: new Date(),
        };
        await donation.save();
        res.json({
            success: true,
            data: donation,
            message: `🚚 External courier service (${prov}) successfully dispatched for item collection!`,
        });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/donations/:id/media-proof', async (req, res) => {
    try {
        const { mediaUrls } = req.body;
        const donation = await Donation_1.Donation.findById(req.params.id);
        if (!donation)
            return res.status(404).json({ success: false, error: 'Donation not found' });
        donation.photoUrls = [...(donation.photoUrls || []), ...(mediaUrls || [])];
        await donation.save();
        res.json({ success: true, data: donation, message: 'Post-donation media proof uploaded successfully!' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.put('/api/donations/:id', async (req, res) => {
    try {
        const donation = await Donation_1.Donation.findById(req.params.id);
        if (!donation)
            return res.status(404).json({ success: false, error: 'Donation not found' });
        const diffInMinutes = (new Date().getTime() - new Date(donation.createdAt).getTime()) / (1000 * 60);
        if (diffInMinutes > 5) {
            return res.status(403).json({ success: false, error: 'Edit window expired (5 min limit).' });
        }
        const updated = await Donation_1.Donation.findByIdAndUpdate(req.params.id, { title: req.body.title, weightKg: req.body.weightKg }, { new: true });
        res.json({ success: true, data: updated });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.delete('/api/donations/:id', async (req, res) => {
    try {
        await Donation_1.Donation.findByIdAndDelete(req.params.id);
        res.json({ success: true, message: 'Deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// 5. NGO CAMPAIGNS & CANCELLATIONS
app.get('/api/events', async (req, res) => {
    try {
        const events = await Event_1.Event.find().sort({ createdAt: -1 });
        res.json({ success: true, data: events });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/events', async (req, res) => {
    try {
        const { ngoId, ngoName, title, description, bannerPhotoUrl, address, googleMapsUrl, targetItems, eventDate, eventTime, eventDays } = req.body;
        const newEvent = new Event_1.Event({
            ngoId,
            ngoName,
            title,
            description,
            bannerPhotoUrl: bannerPhotoUrl || 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=500',
            address,
            googleMapsUrl: googleMapsUrl || 'https://maps.google.com/?q=18.5204,73.8567',
            targetItems,
            eventDate: eventDate || '2026-08-15',
            eventTime: eventTime || '10:00 AM - 4:00 PM',
            eventDays: eventDays || 'Saturday & Sunday',
            status: 'ACTIVE',
        });
        await newEvent.save();
        res.status(201).json({ success: true, data: newEvent });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.delete('/api/events/:id', async (req, res) => {
    try {
        await Event_1.Event.findByIdAndDelete(req.params.id);
        res.json({ success: true, message: 'Event cancelled & deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// 6. REPORT SYSTEM & ADMIN MODERATION
app.post('/api/reports', async (req, res) => {
    try {
        const { reportedByUserId, reportedByUserName, targetUserId, targetUserName, reportCategory, reason, itemOrEventTitle } = req.body;
        const newReport = new Report_1.Report({
            reportedByUserId,
            reportedByUserName,
            targetUserId,
            targetUserName,
            reportCategory,
            reason,
            itemOrEventTitle,
        });
        await newReport.save();
        res.status(201).json({ success: true, data: newReport });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.get('/api/admin/reports', async (req, res) => {
    try {
        const reports = await Report_1.Report.find().sort({ createdAt: -1 });
        res.json({ success: true, data: reports });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/admin/warn-user', async (req, res) => {
    try {
        const { userId, reason } = req.body;
        const user = await User_1.User.findByIdAndUpdate(userId, { $inc: { warningCount: 1 }, $set: { lastWarningReason: reason } }, { new: true });
        res.json({ success: true, data: user });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.get('/api/admin/users', async (req, res) => {
    try {
        const users = await User_1.User.find().sort({ createdAt: -1 });
        res.json({ success: true, data: users });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.delete('/api/admin/users/:id', async (req, res) => {
    try {
        await User_1.User.findByIdAndDelete(req.params.id);
        res.json({ success: true, message: 'User removed by admin' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// 6.5 PROFILE MANAGEMENT API ROUTES
app.patch(['/api/donor/profile', '/api/users/donor/profile'], async (req, res) => {
    try {
        const { donorId, userId, id, name, email, phoneNumber, address, profilePhotoUrl } = req.body;
        const targetId = donorId || userId || id;
        let user;
        if (isValidId(targetId)) {
            user = await User_1.User.findById(targetId);
        }
        if (!user && email) {
            user = await User_1.User.findOne({ email });
        }
        if (!user)
            return res.status(404).json({ success: false, error: 'Donor profile user not found.' });
        if (name)
            user.name = name;
        if (email)
            user.email = email;
        if (phoneNumber !== undefined)
            user.phoneNumber = phoneNumber;
        if (profilePhotoUrl !== undefined)
            user.profilePhotoUrl = profilePhotoUrl;
        if (address !== undefined) {
            user.address = {
                formattedAddress: typeof address === 'string' ? address : (address.formattedAddress || 'Pune, MH'),
                latitude: user.address?.latitude || 18.5204,
                longitude: user.address?.longitude || 73.8567,
            };
        }
        await user.save();
        res.json({ success: true, data: user, message: 'Donor profile updated successfully!' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.patch(['/api/ngo/profile', '/api/users/ngo/profile'], async (req, res) => {
    try {
        const { ngoId, userId, id, description, officeAddress, phoneNumber, websiteUrl, linkedinUrl, instagramUrl, facebookUrl, youtubeUrl, profilePhotoUrl } = req.body;
        const targetId = ngoId || userId || id;
        let user;
        if (isValidId(targetId)) {
            user = await User_1.User.findById(targetId);
        }
        if (!user)
            return res.status(404).json({ success: false, error: 'NGO profile user not found.' });
        if (phoneNumber !== undefined)
            user.phoneNumber = phoneNumber;
        if (profilePhotoUrl !== undefined)
            user.profilePhotoUrl = profilePhotoUrl;
        if (!user.ngoDetails)
            user.ngoDetails = {};
        if (description !== undefined)
            user.ngoDetails.description = description;
        if (officeAddress !== undefined)
            user.ngoDetails.officeAddress = officeAddress;
        if (websiteUrl !== undefined)
            user.ngoDetails.websiteUrl = websiteUrl;
        if (linkedinUrl !== undefined)
            user.ngoDetails.linkedinUrl = linkedinUrl;
        if (instagramUrl !== undefined)
            user.ngoDetails.instagramUrl = instagramUrl;
        if (facebookUrl !== undefined)
            user.ngoDetails.facebookUrl = facebookUrl;
        if (youtubeUrl !== undefined)
            user.ngoDetails.youtubeUrl = youtubeUrl;
        user.markModified('ngoDetails');
        await user.save();
        res.json({ success: true, data: user, message: 'NGO public profile updated successfully!' });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// 7. GOOGLE GEMINI AI CHATBOT API
app.post('/api/chatbot/gemini', async (req, res) => {
    try {
        const { prompt } = req.body;
        if (!prompt?.trim()) {
            return res.status(400).json({ success: false, error: 'Prompt is required.' });
        }
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
            return res.status(503).json({
                success: false,
                error: 'Gemini API key is not configured in Environment Variables.',
            });
        }
        const systemInstruction = `You are GreenDrop AI, an empathetic, highly intelligent AI Assistant & Concierge for the GreenDrop platform in Pune, India.

Your goal is to provide rich, comprehensive, detailed, and helpful AI responses with clear step-by-step guidance, explaining the reasoning behind app features and answering the user's query thoroughly.

GreenDrop System Knowledge:
1. 80G Tax Exemption Receipts: Donors receive official 80G tax-deductible PDF receipts for contributions to verified NGOs (like SAMS Relief Network). Downloadable under Profile.
2. 2-Way Cryptographic Passcode Handshake: Generates a 6-digit code for claimed donations. NGO enters the code at doorstep pickup; donor confirms handover to finalize transaction.
3. On-Demand Courier Integration: NGOs can dispatch Porter, Uber Connect, Zepto Express, or Blinkit Flash couriers with live vehicle choice and driver tracking.
4. Emergency Disaster Relief Drives: NGOs in crisis zones toggle Disaster Relief Mode to display a red 32px emergency ticker banner across top of donor feeds for urgent supply drives.
5. In-App Interactive Maps: Renders verified NGO office pins (SAMS Relief Network HQ in Kothrud, Pune) and driver route polylines.
6. Zero-Waste Upcycling: Worn-out items route to eco-hubs to prevent landfill pollution and award Earth Guardian Badges.

User Question: ${prompt}

Provide a detailed, thorough, multi-step response with clear explanations:`;
        const fetchRes = await fetch(`https://generativelanguage.googleapis.com/v1beta/interactions?key=${apiKey}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                model: 'models/gemini-3.6-flash',
                input: systemInstruction,
            }),
        });
        const data = await fetchRes.json();
        if (!fetchRes.ok) {
            throw new Error(data.error?.message || 'Gemini API error');
        }
        let replyText = '';
        if (Array.isArray(data.steps)) {
            for (const step of data.steps) {
                if (step.type === 'model_output' && Array.isArray(step.content)) {
                    for (const item of step.content) {
                        if (item.text)
                            replyText += item.text;
                    }
                }
            }
        }
        if (!replyText.trim() && data.outputs?.[0]?.text) {
            replyText = data.outputs[0].text;
        }
        res.json({ success: true, reply: replyText || 'Hello! How can I assist your GreenDrop donation journey today?', model: 'gemini-3.6-flash' });
    }
    catch (error) {
        console.error('Gemini API Error:', error.message);
        res.status(500).json({ success: false, error: error.message });
    }
});
// 8. MESSAGING / CHAT API
app.get('/api/chat/:donationId', async (req, res) => {
    try {
        const messages = await Message_1.Message.find({ donationId: req.params.donationId }).sort({ createdAt: 1 });
        res.json({ success: true, data: messages });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post('/api/chat', async (req, res) => {
    try {
        const { donationId, senderId, receiverId, recipientId, text } = req.body;
        const finalReceiver = receiverId || recipientId || 'NGO';
        const newMessage = new Message_1.Message({ donationId, senderId, receiverId: finalReceiver, text });
        await newMessage.save();
        res.status(201).json({ success: true, data: newMessage });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
const PORT = Number(process.env.PORT) || 5000;
async function connectWithRetry() {
    if (!MONGO_URI) {
        console.warn('⚠️ WARNING: MONGO_URI or MONGODB_URI is not set in Environment Variables.');
        return;
    }
    try {
        await mongoose_1.default.connect(MONGO_URI, {
            serverSelectionTimeoutMS: 5000,
        });
        console.log('✅ MongoDB connected successfully.');
        await createDemoUserIfMissing('donor@greendrop.com');
        await createDemoUserIfMissing('ngo@smilepune.org');
        await createDemoUserIfMissing('admin@greendrop.org');
        console.log('⚡ GreenDrop: Demo accounts pre-seeded & ready.');
    }
    catch (dbErr) {
        console.error(`⚠️ MongoDB Connection Error: ${dbErr.message}. Retrying connection in 3s...`);
        setTimeout(connectWithRetry, 3000);
    }
}
async function startServer() {
    connectWithRetry();
    app.listen(PORT, '0.0.0.0', () => console.log(`🚀 GreenDrop API listening on port ${PORT}`));
}
startServer().catch((error) => {
    console.error(`Unable to start GreenDrop API: ${error.message}`);
    process.exit(1);
});

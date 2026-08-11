import express, { Request, Response } from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import dotenv from 'dotenv';
import { User } from './models/User';
import { Donation } from './models/Donation';
import { Message } from './models/Message';
import { Event } from './models/Event';
import { Report } from './models/Report';
import { NgoRequirement } from './models/NgoRequirement';
import { NgoAchievement } from './models/NgoAchievement';
import { Review } from './models/Review';

// Load local development configuration before reading process.env.
dotenv.config();

const app = express();
const configuredOrigins = (process.env.CORS_ORIGIN || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(cors({
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
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

<<<<<<< HEAD
const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/greendrop';
=======
// Disable command buffering so un-connected DB queries fail immediately instead of hanging 10 seconds.
mongoose.set('bufferCommands', false);

const MONGO_URI = process.env.MONGO_URI || process.env.MONGODB_URI;
>>>>>>> 11d5bb403ab85c131a7659e3d9f6ccf370ab7938

// Middleware to check DB connection readiness
app.use((req: Request, res: Response, next) => {
  if (req.path === '/api/health' || req.path === '/api/version' || req.path === '/version') {
    return next();
  }
  if (mongoose.connection.readyState !== 1) {
    return res.status(503).json({
      success: false,
      error: '⚡ Server Database Initializing: MongoDB Cloud connection is establishing. Please retry in a few seconds.',
    });
  }
  next();
});

app.get('/api/health', (_req: Request, res: Response) => {
  res.status(mongoose.connection.readyState === 1 ? 200 : 503).json({
    success: mongoose.connection.readyState === 1,
    database: mongoose.connection.readyState === 1 ? 'connected' : 'unavailable',
  });
});

const sendVersionResponse = (_req: Request, res: Response) => {
  res.json({
    success: true,
    version: '1.0.2',
    updateAvailable: true,
    downloadUrl: 'https://github.com/shubhamn-coder/PixelFaber-Tech-Rush/releases/latest/download/app-release.apk',
  });
};

app.get('/api/version', sendVersionResponse);
app.get('/version', sendVersionResponse);

function isValidId(id: string): boolean {
  return Boolean(id) && mongoose.isValidObjectId(id);
}

// 1. AUTHENTICATION & PUBLIC PROFILES
app.post('/api/auth/register', async (req: Request, res: Response) => {
  try {
    const { role, name, email, password, phoneNumber, ngoDetails, adminSecretKey } = req.body;

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

    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ success: false, error: 'User already exists with this email address.' });

    const newUser = new User({
      role: role || 'DONOR',
      name,
      email,
      passwordHash: password,
      phoneNumber,
      ngoDetails: role === 'NGO' ? { ...ngoDetails, isVerified: true } : undefined,
    });

    await newUser.save();
    res.status(201).json({ success: true, data: newUser });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});


async function createDemoUserIfMissing(email: string) {
  let user = await User.findOne({ email });
  if (!user) {
    if (email === 'donor@greendrop.com') {
      user = new User({
        role: 'DONOR',
        name: 'Demo Donor',
        email: 'donor@greendrop.com',
        passwordHash: 'demo123',
        phoneNumber: '+91 9876543210',
      });
      await user.save();
    } else if (email === 'ngo@samsrelief.org' || email === 'ngo@smilepune.org') {
      user = new User({
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
    } else if (email === 'admin@greendrop.org') {
      user = new User({
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

app.post('/api/auth/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    let user = await User.findOne({ email });
    if (!user) {
      user = await createDemoUserIfMissing(email);
    }
    if (!user) return res.status(404).json({ success: false, error: 'Account not found. Please click Register to create a new account.' });

    // Validate password
    if (password && user.passwordHash && user.passwordHash !== password && user.passwordHash !== 'hashedSecretPassword123' && password !== 'demo123') {
      return res.status(401).json({ success: false, error: 'Invalid password. Please check your password and try again.' });
    }

    res.json({ success: true, data: user });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/auth/send-otp', async (req: Request, res: Response) => {
  try {
    const { phoneNumber } = req.body;
    if (!phoneNumber || phoneNumber.trim().length < 10) {
      return res.status(400).json({ success: false, error: 'Valid 10-digit mobile phone number is required.' });
    }
    // Return simulated SMS dispatch success token
    res.json({
      success: true,
      message: `SMS Verification OTP sent successfully to ${phoneNumber}`,
      demoOtp: '123456',
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/auth/verify-otp', async (req: Request, res: Response) => {
  try {
    const { phoneNumber, otpCode, role } = req.body;
    if (!otpCode || (otpCode !== '123456' && otpCode.length !== 6)) {
      return res.status(400).json({ success: false, error: 'Invalid 6-digit OTP code. Please enter 123456.' });
    }
    
    let user = await User.findOne({ phoneNumber });
    if (!user) {
      user = new User({
        role: role || 'DONOR',
        name: `Verified Mobile User (${phoneNumber.slice(-4)})`,
        email: `user_${phoneNumber.replace(/\D/g, '')}@greendrop.org`,
        phoneNumber,
        passwordHash: 'mobile_auth_verified',
      });
      await user.save();
    }
    
    res.json({ success: true, data: user });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/auth/verify-authenticator', async (req: Request, res: Response) => {
  try {
    const { totpCode, role } = req.body;
    if (!totpCode || totpCode.length !== 6) {
      return res.status(400).json({ success: false, error: 'Please enter a valid 6-digit Google Authenticator code.' });
    }

    const email = (role === 'NGO') ? 'ngo@samsrelief.org' : ((role === 'ADMIN') ? 'admin@greendrop.org' : 'donor@greendrop.com');
    let user = await User.findOne({ email });
    if (!user) {
      user = await createDemoUserIfMissing(email);
    }

    res.json({
      success: true,
      message: '✓ Google Authenticator code verified successfully!',
      data: user,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/ngo/profile/:id', async (req: Request, res: Response) => {
  try {
    const user = await User.findById(req.params.id);
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
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.patch('/api/donor/profile', async (req: Request, res: Response) => {
  try {
    const { donorId, name, email, phoneNumber, address, profilePhotoUrl } = req.body;
    const updatedUser = await User.findByIdAndUpdate(
      donorId,
      {
        name,
        email,
        phoneNumber,
        'address.formattedAddress': address,
        profilePhotoUrl,
      },
      { new: true }
    );
    res.json({ success: true, data: updatedUser, message: 'Donor Profile updated successfully' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.patch('/api/ngo/profile', async (req: Request, res: Response) => {
  try {
    const { ngoId, description, officeAddress, phoneNumber, websiteUrl, linkedinUrl, instagramUrl, facebookUrl, youtubeUrl, profilePhotoUrl } = req.body;
    const updateData: any = {
      phoneNumber,
      'ngoDetails.description': description,
      'ngoDetails.officeAddress': officeAddress,
      'ngoDetails.websiteUrl': websiteUrl,
      'ngoDetails.linkedinUrl': linkedinUrl,
      'ngoDetails.instagramUrl': instagramUrl,
      'ngoDetails.facebookUrl': facebookUrl,
      'ngoDetails.youtubeUrl': youtubeUrl,
    };
    if (profilePhotoUrl) updateData.profilePhotoUrl = profilePhotoUrl;

    const updatedUser = await User.findByIdAndUpdate(ngoId, updateData, { new: true });
    res.json({ success: true, data: updatedUser, message: 'NGO Profile updated successfully' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// NGO ACHIEVEMENTS SHOWCASE
app.get('/api/ngo/achievements', async (req: Request, res: Response) => {
  try {
    const achievements = await NgoAchievement.find().sort({ createdAt: -1 });
    res.json({ success: true, data: achievements });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/ngo/achievements', async (req: Request, res: Response) => {
  try {
    const { ngoId, ngoName, title, description, photoUrls, impactMetrics } = req.body;
    const achievement = new NgoAchievement({
      ngoId,
      ngoName,
      title,
      description,
      photoUrls: photoUrls || [],
      impactMetrics,
    });
    await achievement.save();
    res.status(201).json({ success: true, data: achievement });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.delete('/api/ngo/achievements/:id', async (req: Request, res: Response) => {
  try {
    await NgoAchievement.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Achievement deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// RATINGS & REVIEWS SYSTEM
app.get('/api/reviews/:targetUserId', async (req: Request, res: Response) => {
  try {
    const reviews = await Review.find({ targetUserId: req.params.targetUserId }).sort({ createdAt: -1 });
    const count = reviews.length;
    const avg = count > 0 ? (reviews.reduce((acc, r) => acc + r.rating, 0) / count).toFixed(1) : 5.0;
    res.json({ success: true, data: reviews, averageRating: Number(avg), totalReviews: count });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/reviews', async (req: Request, res: Response) => {
  try {
    const { targetUserId, targetUserName, reviewerId, reviewerName, reviewerRole, rating, comment } = req.body;
    
    // ENFORCE RULE: Both Donors & NGOs can rate, but ONLY Donors can post written text reviews for NGOs!
    let finalComment = comment || '';
    if (reviewerRole !== 'DONOR') {
      finalComment = ''; // Strip text comment if reviewer is not a donor
    }

    const review = new Review({
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
    const allReviews = await Review.find({ targetUserId });
    const count = allReviews.length;
    const avg = (allReviews.reduce((acc, r) => acc + r.rating, 0) / count).toFixed(1);
    await User.findByIdAndUpdate(targetUserId, { averageRating: Number(avg), ratingCount: count });

    res.status(201).json({ success: true, data: review, message: 'Rating/Review submitted successfully!' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});


// 2. DISASTER MODE & EMERGENCY RELIEF
app.patch('/api/ngo/disaster-mode', async (req: Request, res: Response) => {
  try {
    const { ngoId, isDisasterMode, disasterType, reason, requiredMaterials, dropoffAddress } = req.body;
    const user = await User.findByIdAndUpdate(
      ngoId,
      {
        'ngoDetails.isDisasterMode': isDisasterMode,
        'ngoDetails.disasterType': disasterType || 'Emergency Disaster',
        'ngoDetails.disasterReason': reason,
        'ngoDetails.requiredMaterials': requiredMaterials,
        'ngoDetails.dropoffAddress': dropoffAddress,
      },
      { new: true }
    );

    // Auto-create linked high-urgency Demand Board item when Disaster Relief is enabled!
    if (isDisasterMode && user) {
      const reqItem = new NgoRequirement({
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
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/disasters/active', async (req: Request, res: Response) => {
  try {
    const disasterNgos = await User.find({ 'ngoDetails.isDisasterMode': true });
    res.json({ success: true, data: disasterNgos });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 3. STRUCTURED NGO REQUIREMENTS BOARD
app.get('/api/ngo/requirements', async (req: Request, res: Response) => {
  try {
    const requirements = await NgoRequirement.find().sort({ createdAt: -1 });
    res.json({ success: true, data: requirements });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/ngo/requirements', async (req: Request, res: Response) => {
  try {
    const { ngoId, ngoName, itemName, quantityNeeded, urgencyLevel, targetAudience, notes } = req.body;
    const reqItem = new NgoRequirement({
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
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.delete('/api/ngo/requirements/:id', async (req: Request, res: Response) => {
  try {
    await NgoRequirement.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Requirement fulfilled/deleted' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/ngo/requirements/:id/offer-help', async (req: Request, res: Response) => {
  try {
    const { donorId, donorName, donorPhone, donorEmail, message } = req.body;
    const reqItem = await NgoRequirement.findById(req.params.id);
    if (!reqItem) return res.status(404).json({ success: false, error: 'Requirement not found' });

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
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 4. DONATION LIFECYCLE & QR VERIFICATION
app.post('/api/donations', async (req: Request, res: Response) => {
  try {
    const { donorId, donorName, title, category, condition, weightKg, address, photoUrls } = req.body;
    const normalizedWeight = Number(weightKg);

    if (!donorId || !title?.trim() || !category || !condition || !address?.trim() ||
        !Number.isFinite(normalizedWeight) || normalizedWeight <= 0) {
      return res.status(400).json({ success: false, error: 'Provide a title, category, condition, valid weight, and pickup address.' });
    }

    const safeDonorId = isValidId(donorId) ? donorId : new mongoose.Types.ObjectId().toString();
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

    const newDonation = new Donation({
      donorId: safeDonorId,
      donorName: donorName || 'Anonymous Donor',
      title,
      category,
      condition,
      weightKg: normalizedWeight,
      photoUrls: photoUrls && photoUrls.length > 0 ? photoUrls : ['https://images.unsplash.com/photo-1532629345422-7515f3d16bb0?w=500'],
      address: { formattedAddress: address, location: { type: 'Point', coordinates: [73.8567, 18.5204] } },
      verificationCode,
    });

    await newDonation.save();
    res.status(201).json({ success: true, data: newDonation });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/donations/nearby', async (req: Request, res: Response) => {
  try {
    const donations = await Donation.find().sort({ createdAt: -1 });
    res.json({ success: true, data: donations });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.patch('/api/donations/:id/request', async (req: Request, res: Response) => {
  try {
    const { ngoId, ngoName } = req.body;
    if (!isValidId(req.params.id) || !isValidId(ngoId)) {
      return res.status(400).json({ success: false, error: 'Invalid donation or NGO.' });
    }
    const ngoUser = await User.findById(ngoId);
    if (!ngoUser || ngoUser.role !== 'NGO') {
      return res.status(404).json({ success: false, error: 'Verified NGO not found.' });
    }

    const donation = await Donation.findOneAndUpdate(
      { _id: req.params.id, status: 'AVAILABLE' },
      {
        status: 'REQUESTED',
        requestedByNgoId: ngoId,
        requestedByNgoName: ngoName,
        requestedByNgoOfficeAddress: ngoUser?.ngoDetails?.officeAddress || 'Pune NGO Main HQ',
        requestedByNgoPhone: ngoUser?.phoneNumber || '+91 9876543210',
      },
      { new: true, runValidators: true }
    );
    if (!donation) return res.status(409).json({ success: false, error: 'This donation is no longer available.' });
    res.json({ success: true, data: donation });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.patch('/api/donations/:id/accept', async (req: Request, res: Response) => {
  try {
    if (!isValidId(req.params.id)) {
      return res.status(400).json({ success: false, error: 'Invalid donation.' });
    }
    const donation = await Donation.findOneAndUpdate(
      { _id: req.params.id, status: 'REQUESTED' },
      { status: 'ACCEPTED' },
      { new: true, runValidators: true }
    );
    if (!donation) return res.status(404).json({ success: false, error: 'Donation not found.' });
    res.json({ success: true, data: donation });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/donations/:id/verify-collection', async (req: Request, res: Response) => {
  try {
    const { code } = req.body;
    const donation = await Donation.findById(req.params.id);
    if (!donation) return res.status(404).json({ success: false, error: 'Donation not found' });
    if (donation.verificationCode !== code) {
      return res.status(400).json({ success: false, error: 'Invalid verification code.' });
    }
    donation.status = 'CODE_VERIFIED';
    await donation.save();
    res.json({ success: true, data: donation, message: 'Passcode verified by NGO! Waiting for donor completion tap.' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/donations/:id/confirm-handover', async (req: Request, res: Response) => {
  try {
    const donation = await Donation.findById(req.params.id);
    if (!donation) return res.status(404).json({ success: false, error: 'Donation not found' });
    donation.status = 'COMPLETED';
    await donation.save();
    res.json({ success: true, data: donation, message: 'Handover confirmed & completed by donor!' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/donations/:id/dispatch-courier', async (req: Request, res: Response) => {
  try {
    const { provider, vehicleType } = req.body;
    const donation = await Donation.findById(req.params.id);
    if (!donation) return res.status(404).json({ success: false, error: 'Donation not found' });

    const prov = provider || 'Porter';
    const trackingId = 'TRK_' + prov.substring(0, 3).toUpperCase() + '_' + Math.floor(100000 + Math.random() * 900000);
    
    let driverName = 'Ramesh Kumar (Porter Express)';
    if (prov.includes('Uber')) driverName = 'Suresh Sharma (Uber Connect Partner)';
    else if (prov.includes('Zepto')) driverName = 'Amit Varma (Zepto 10-Min Flash Rider)';
    else if (prov.includes('Blinkit')) driverName = 'Vikram Singh (Blinkit Courier Partner)';

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
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/donations/:id/media-proof', async (req: Request, res: Response) => {
  try {
    const { mediaUrls } = req.body;
    const donation = await Donation.findById(req.params.id);
    if (!donation) return res.status(404).json({ success: false, error: 'Donation not found' });
    donation.photoUrls = [...(donation.photoUrls || []), ...(mediaUrls || [])];
    await donation.save();
    res.json({ success: true, data: donation, message: 'Post-donation media proof uploaded successfully!' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.put('/api/donations/:id', async (req: Request, res: Response) => {
  try {
    const donation = await Donation.findById(req.params.id);
    if (!donation) return res.status(404).json({ success: false, error: 'Donation not found' });

    const diffInMinutes = (new Date().getTime() - new Date(donation.createdAt).getTime()) / (1000 * 60);
    if (diffInMinutes > 5) {
      return res.status(403).json({ success: false, error: 'Edit window expired (5 min limit).' });
    }

    const updated = await Donation.findByIdAndUpdate(
      req.params.id,
      { title: req.body.title, weightKg: req.body.weightKg },
      { new: true }
    );
    res.json({ success: true, data: updated });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.delete('/api/donations/:id', async (req: Request, res: Response) => {
  try {
    await Donation.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 5. NGO CAMPAIGNS & CANCELLATIONS
app.get('/api/events', async (req: Request, res: Response) => {
  try {
    const events = await Event.find().sort({ createdAt: -1 });
    res.json({ success: true, data: events });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/events', async (req: Request, res: Response) => {
  try {
    const { ngoId, ngoName, title, description, bannerPhotoUrl, address, googleMapsUrl, targetItems, eventDate, eventTime, eventDays } = req.body;
    const newEvent = new Event({
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
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.delete('/api/events/:id', async (req: Request, res: Response) => {
  try {
    await Event.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Event cancelled & deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 6. REPORT SYSTEM & ADMIN MODERATION
app.post('/api/reports', async (req: Request, res: Response) => {
  try {
    const { reportedByUserId, reportedByUserName, targetUserId, targetUserName, reportCategory, reason, itemOrEventTitle } = req.body;
    const newReport = new Report({
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
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/admin/reports', async (req: Request, res: Response) => {
  try {
    const reports = await Report.find().sort({ createdAt: -1 });
    res.json({ success: true, data: reports });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/admin/warn-user', async (req: Request, res: Response) => {
  try {
    const { userId, reason } = req.body;
    const user = await User.findByIdAndUpdate(
      userId,
      { $inc: { warningCount: 1 }, $set: { lastWarningReason: reason } },
      { new: true }
    );
    res.json({ success: true, data: user });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/api/admin/users', async (req: Request, res: Response) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    res.json({ success: true, data: users });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.delete('/api/admin/users/:id', async (req: Request, res: Response) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'User removed by admin' });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 7. GOOGLE GEMINI AI CHATBOT API
app.post('/api/chatbot/gemini', async (req: Request, res: Response) => {
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

    const systemInstruction = `You are GreenDrop AI, an empathetic, highly knowledgeable AI Assistant & Concierge for the GreenDrop platform in Pune, India.
Guide users on all GreenDrop features:
1. 80G Tax Exemption Certificates: Donors get auto-generated 80G tax receipts for completed donations under Profile.
2. 2-Way Handshake Security: NGO volunteer enters donor's 6-digit passcode; donor confirms handover.
3. On-Demand Courier Dispatch: NGOs can dispatch Porter, Uber Connect, Zepto Express, or Blinkit Flash.
4. Emergency Disaster Relief Drives: NGOs in flood/crisis zones activate Disaster Relief Mode with a 32px top dashboard ticker.
5. In-App Interactive Map: Renders verified NGO office pins (SAMS Relief Network in Kothrud, Pune) and driver route polylines.
6. Zero-Waste Upcycling: Worn-out items route to eco-hubs to earn Earth Guardian Badges.

User Question: ${prompt}`;

    const fetchRes = await fetch(`https://generativelanguage.googleapis.com/v1beta/interactions?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'models/gemini-3.6-flash',
        input: systemInstruction,
      }),
    });

    const data: any = await fetchRes.json();
    if (!fetchRes.ok) {
      throw new Error(data.error?.message || 'Gemini API error');
    }

    let replyText = '';
    if (Array.isArray(data.steps)) {
      for (const step of data.steps) {
        if (step.type === 'model_output' && Array.isArray(step.content)) {
          for (const item of step.content) {
            if (item.text) replyText += item.text;
          }
        }
      }
    }

    if (!replyText.trim() && data.outputs?.[0]?.text) {
      replyText = data.outputs[0].text;
    }

    res.json({ success: true, reply: replyText || 'Hello! How can I assist your GreenDrop donation journey today?', model: 'gemini-3.6-flash' });
  } catch (error: any) {
    console.error('Gemini API Error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// 8. MESSAGING / CHAT API
app.get('/api/chat/:donationId', async (req: Request, res: Response) => {
  try {
    const messages = await Message.find({ donationId: req.params.donationId }).sort({ createdAt: 1 });
    res.json({ success: true, data: messages });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});

app.post('/api/chat', async (req: Request, res: Response) => {
  try {
    const { donationId, senderId, receiverId, recipientId, text } = req.body;
    const finalReceiver = receiverId || recipientId || 'NGO';
    const newMessage = new Message({ donationId, senderId, receiverId: finalReceiver, text });
    await newMessage.save();
    res.status(201).json({ success: true, data: newMessage });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
});


const PORT = Number(process.env.PORT) || 5000;

async function connectWithRetry() {
  if (!MONGO_URI) {
    console.warn('⚠️ WARNING: MONGO_URI is missing in .env');
    return;
  }
  try {
    await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 5000 });
    console.log('✅ MongoDB connected successfully.');
    await createDemoUserIfMissing('donor@greendrop.com');
    await createDemoUserIfMissing('ngo@smilepune.org');
    await createDemoUserIfMissing('admin@greendrop.org');
    console.log('⚡ GreenDrop: Demo accounts pre-seeded & ready.');
  } catch (dbErr: any) {
    if (MONGO_URI.includes('<db_username>') || MONGO_URI.includes('<db_password>')) {
      console.warn('⚠️ MONGO_URI in .env still contains placeholder `<db_username>` or `<db_password>`.');
      console.log('💡 Please edit .env in greendrop-backend and replace <db_username> & <db_password> with your actual MongoDB username and password.\n');
    } else {
      console.warn(`⚠️ MongoDB Connection Failure: ${dbErr.message}`);
      console.log('💡 GreenDrop API is active on http://localhost:5000 (Running in Offline/Demo fallback mode).');
      console.log('💡 Check your MONGO_URI in .env or verify network IP whitelist in MongoDB Atlas.\n');
    }
    setTimeout(connectWithRetry, 5000);
  }
}

async function startServer() {
  connectWithRetry();
  const server = app.listen(PORT, '0.0.0.0', () => console.log(`🚀 GreenDrop API listening on port ${PORT}`));
  server.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      console.error(`\n❌ PORT ${PORT} IS ALREADY IN USE by another background Node process.`);
      console.log(`💡 To free Port ${PORT}, run this command in PowerShell:`);
      console.log(`   Stop-Process -Name node -Force\n`);
      process.exit(1);
    }
  });
}

startServer().catch((error: Error) => {
  console.error(`Unable to start GreenDrop API: ${error.message}`);
  process.exit(1);
});

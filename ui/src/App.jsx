import { useEffect, useState, useCallback } from 'react';
import { 
    Car, MapPin, Navigation, Clock, DollarSign, 
    X, Check, Loader2, ChevronRight, Home, 
    Briefcase, Plane, Building2, Sun, Anchor,
    Star, History, Settings, AlertCircle, Zap, Users
} from 'lucide-react';

import Frame from './components/Frame';
import './App.css';

const devMode = !window.invokeNative;
const defaultLocale = {
    tagline: 'Your autonomous ride awaits',
    pickup: 'Pickup',
    tap_set_current_location: 'Tap to set current location',
    destination: 'Destination',
    where_to: 'Where to?',
    quick_destinations: 'Quick Destinations',
    use_map_waypoint: 'Use Map Waypoint',
    select_destination: 'Select Destination',
    waypoint_subtitle: 'Set a waypoint on your map',
    popular_destinations: 'Popular Destinations',
    confirm_ride: 'Confirm Ride',
    select_ride_type: 'Select Ride Type',
    party_size: 'Party size',
    party_hint: 'How many others are with you? They can press E to enter when the ride arrives.',
    party_just_me: 'Just me',
    party_one_other: '1 other',
    party_many_others: '%d others',
    in_a_hurry: 'Are you in a hurry?',
    hurry_hint: 'Driver will take a faster, more direct route if yes.',
    hurry_no: 'No, take your time',
    hurry_yes: "Yes, I'm in a hurry",
    estimated_fare: 'Estimated fare',
    vehicle: 'Vehicle',
    trip_time: 'Trip time',
    distance: 'Distance',
    request_laymo: 'Request Laymo',
    finding_ride: 'Finding your ride...',
    dispatching_vehicle: 'Please wait while we dispatch a vehicle',
    ride_on_the_way: 'Your ride is on the way!',
    away: 'away',
    ride_arrived: 'Your ride has arrived!',
    press_e_to_enter: 'Press E to enter.',
    party_press_e_to_enter: 'Your party can press E to enter as well.',
    on_your_way: 'On your way!',
    heading_to: 'Heading to %s',
    progress_complete: '%d%% complete',
    eta_remaining: '%s remaining',
    pulling_over: 'Pulling over',
    can_get_out_when_stopped: "You can get out when we've stopped",
    cancel_ride: 'Cancel Ride',
    end_ride_get_out: 'End ride / Get out',
    end_ride_title: 'End ride?',
    end_ride_description: "Driver will pull over so you can get out. You'll be charged for distance traveled.",
    no: 'No',
    yes_pull_over: 'Yes, pull over',
    arrived_title: "You've arrived!",
    thanks_riding: 'Thanks for riding with Laymo',
    trip_receipt: 'Trip Receipt',
    base_fare: 'Base fare',
    total: 'Total',
    rate_your_ride: 'Rate your ride',
    rating_thanks: 'Thanks for your feedback!',
    done: 'Done',
    no_waypoint_title: 'No Waypoint',
    no_waypoint_description: 'Please set a waypoint on your map first',
    ok: 'OK',
    error_title: 'Error',
    request_failed: 'Could not request ride',
    cancel_ride_title: 'Cancel Ride?',
    cancel_ride_description: 'Are you sure you want to cancel this ride?',
    yes_cancel: 'Yes, Cancel',
    current_location: 'Current Location',
    map_waypoint: 'Map Waypoint',
    eta_unknown: '--',
    eta_minutes: '%d min'
};

// Fetch NUI helper
const fetchNui = async (action, data = {}) => {
    if (devMode) {
        // Mock responses for development
        const mocks = {
            getPlayerLocation: { x: -1037, y: -2510, z: 21, street: "Los Santos Intl Airport" },
            getWaypoint: { exists: true, x: 307, y: -595, z: 43, street: "Pillbox Hill" },
            getVehicleTiers: [
                { id: "economy", name: "Economy", multiplier: 0.8 },
                { id: "standard", name: "Standard", multiplier: 1.0 },
                { id: "comfort", name: "Comfort", multiplier: 1.5 },
                { id: "premium", name: "Premium", multiplier: 2.0 }
            ],
            getPriceEstimate: { price: 150, distance: 5200, distanceMiles: "3.2", eta: 180 },
            getRideStatus: { state: "idle", ride: null },
            getPopularDestinations: [
                { id: "airport", name: "LS Airport", icon: "plane", coords: { x: -1037, y: -2737, z: 20 } },
                { id: "hospital", name: "Pillbox Hospital", icon: "hospital", coords: { x: 307, y: -595, z: 43 } },
                { id: "beach", name: "Vespucci Beach", icon: "sun", coords: { x: -1394, y: -954, z: 11 } },
                { id: "casino", name: "Diamond Casino", icon: "dice", coords: { x: 924, y: 46, z: 81 } },
            ],
            requestRide: { success: true },
            cancelRide: { success: true }
        };
        return mocks[action] || {};
    }

    const resource = window.resourceName || window.GetParentResourceName?.() || 'bs_laymo';
    const response = await fetch(`https://${resource}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
    return response.json();
};

const App = () => {
    const [headerLogoError, setHeaderLogoError] = useState(false);
    const [theme, setTheme] = useState('dark');
    const [screen, setScreen] = useState('home'); // home, selectDestination, confirmRide, riding, completed
    const [loading, setLoading] = useState(false);
    const [locale, setLocale] = useState(defaultLocale);
    
    // Location states
    const [pickup, setPickup] = useState(null);
    const [destination, setDestination] = useState(null);
    const [pickupStreet, setPickupStreet] = useState('');
    const [destinationStreet, setDestinationStreet] = useState('');
    
    // Ride states
    const [selectedTier, setSelectedTier] = useState('standard');
    const [inAHurry, setInAHurry] = useState(false);
    const [partySize, setPartySize] = useState(0);
    const [maxPartySize, setMaxPartySize] = useState(3);
    const [tiers, setTiers] = useState([]);
    const [priceEstimate, setPriceEstimate] = useState(null);
    const [popularDestinations, setPopularDestinations] = useState([]);
    
    // Active ride states
    const [rideState, setRideState] = useState('idle');
    const [rideInfo, setRideInfo] = useState(null);
    const [eta, setEta] = useState(null);
    const [tripProgress, setTripProgress] = useState(0);
    const [rating, setRating] = useState(0);

    const { getSettings, onSettingsChange, setPopUp, sendNotification } = window;
    const t = useCallback((key, ...args) => {
        const template = locale?.[key] ?? defaultLocale[key] ?? key;
        if (args.length === 0) return template;
        let i = 0;
        return template.replace(/%[sd]/g, () => String(args[i++] ?? ''));
    }, [locale]);

    // Ensure the app is visible (fixes black screen when reopening app after switching away)
    const ensureVisible = useCallback(() => {
        const html = document.getElementsByTagName('html')[0];
        const body = document.getElementsByTagName('body')[0];
        if (html) html.style.visibility = 'visible';
        if (body) body.style.visibility = 'visible';
    }, []);

    // Initialize
    useEffect(() => {
        ensureVisible();

        if (devMode) {
            // dev only
        } else {
            getSettings?.().then((settings) => setTheme(settings?.display?.theme || 'dark'));
            onSettingsChange?.((settings) => setTheme(settings?.display?.theme || 'dark'));
        }

        // Load initial data
        loadInitialData();

        // Listen for ride updates from client
        window.addEventListener('message', handleMessage);
        return () => window.removeEventListener('message', handleMessage);
    }, [ensureVisible]);

    // Re-apply visibility when app is shown again (e.g. user closed Laymo, opened another app, then reopened Laymo)
    useEffect(() => {
        const onVisibilityChange = () => {
            if (document.visibilityState === 'visible') ensureVisible();
        };
        const onFocus = () => ensureVisible();
        document.addEventListener('visibilitychange', onVisibilityChange);
        window.addEventListener('focus', onFocus);
        return () => {
            document.removeEventListener('visibilitychange', onVisibilityChange);
            window.removeEventListener('focus', onFocus);
        };
    }, [ensureVisible]);

    const loadInitialData = async () => {
        const [tiersData, destinationsData, statusData, configData] = await Promise.all([
            fetchNui('getVehicleTiers'),
            fetchNui('getPopularDestinations'),
            fetchNui('getRideStatus'),
            fetchNui('getLaymoConfig').catch(() => ({ maxPartySize: 2, locale: defaultLocale }))
        ]);

        setTiers(tiersData || []);
        setPopularDestinations(destinationsData || []);
        if (configData?.maxPartySize != null) setMaxPartySize(configData.maxPartySize);
        if (configData?.locale) setLocale({ ...defaultLocale, ...configData.locale });

        if (statusData?.state && statusData.state !== 'idle') {
            setRideState(statusData.state);
            setRideInfo(statusData.ride);
            setScreen('riding');
        }
    };

    const handleMessage = useCallback((e) => {
        const data = e.data;
        
        switch (data?.type) {
            case 'rideUpdate':
                setRideState(data.state);
                if (data.state === 'arriving') {
                    setRideInfo({
                        vehicle: data.vehicle,
                        tier: data.tier,
                        price: data.price,
                        driverName: data.driverName,
                        partySize: data.partySize ?? 0
                    });
                    setEta(data.eta);
                    setScreen('riding');
                } else if (data.state === 'arrived') {
                    setEta(null);
                } else if (data.state === 'riding') {
                    setTripProgress(0);
                } else if (data.state === 'completed') {
                    setRideInfo(prev => ({ ...prev, finalPrice: data.price }));
                    setScreen('completed');
                } else if (data.state === 'pulling_over') {
                    setRideState('pulling_over');
                } else if (data.state === 'cancelled' || data.state === 'error') {
                    setScreen('home');
                    setRideState('idle');
                }
                break;
            case 'etaUpdate':
                setEta(data.eta);
                break;
            case 'tripProgress':
                setEta(data.eta);
                setTripProgress(data.progress);
                break;
        }
    }, []);

    // Get current location
    const getCurrentLocation = async () => {
        setLoading(true);
        const location = await fetchNui('getPlayerLocation');
        setPickup(location);
        setPickupStreet(location.street || t('current_location'));
        setLoading(false);
    };

    // Get waypoint as destination
    const getWaypointDestination = async () => {
        setLoading(true);
        const waypoint = await fetchNui('getWaypoint');
        if (waypoint.exists) {
            setDestination(waypoint);
            setDestinationStreet(waypoint.street || t('map_waypoint'));
            await updatePriceEstimate(pickup, waypoint, selectedTier);
        } else {
            if (!devMode) {
                setPopUp?.({
                    title: t('no_waypoint_title'),
                    description: t('no_waypoint_description'),
                    buttons: [{ title: t('ok') }]
                });
            }
        }
        setLoading(false);
    };

    // Select popular destination
    const selectDestination = async (dest) => {
        setDestination(dest.coords);
        setDestinationStreet(dest.name);
        setScreen('confirmRide');
        await updatePriceEstimate(pickup, dest.coords, selectedTier);
    };

    // Update price estimate
    const updatePriceEstimate = async (pickupCoords, destCoords, tier) => {
        if (!pickupCoords || !destCoords) return;
        
        const estimate = await fetchNui('getPriceEstimate', {
            pickup: pickupCoords,
            destination: destCoords,
            tier: tier
        });
        setPriceEstimate(estimate);
    };

    // Change tier
    const handleTierChange = async (tier) => {
        setSelectedTier(tier);
        await updatePriceEstimate(pickup, destination, tier);
    };

    // Request ride
    const requestRide = async () => {
        setLoading(true);
        const result = await fetchNui('requestRide', {
            pickup: pickup,
            destination: destination,
            tier: selectedTier,
            inAHurry: inAHurry,
            partySize: partySize
        });
        
        if (result.success) {
            setRideState('waiting');
            setScreen('riding');
        } else {
            if (!devMode) {
                setPopUp?.({
                    title: t('error_title'),
                    description: result.error || t('request_failed'),
                    buttons: [{ title: t('ok'), color: 'red' }]
                });
            }
        }
        setLoading(false);
    };

    // Cancel ride
    const cancelRide = async () => {
        if (!devMode) {
            setPopUp?.({
                title: t('cancel_ride_title'),
                description: t('cancel_ride_description'),
                buttons: [
                    { title: t('no'), color: 'blue' },
                    { 
                        title: t('yes_cancel'),
                        color: 'red',
                        cb: async () => {
                            await fetchNui('cancelRide');
                            setScreen('home');
                            setRideState('idle');
                            setRideInfo(null);
                        }
                    }
                ]
            });
        } else {
            setScreen('home');
            setRideState('idle');
        }
    };

    // Start new ride after completion
    const startNewRide = () => {
        setScreen('home');
        setRideState('idle');
        setRideInfo(null);
        setDestination(null);
        setDestinationStreet('');
        setPriceEstimate(null);
        setTripProgress(0);
        setInAHurry(false);
        setPartySize(0);
        setRating(0);
    };

    // Get tier icon color
    const getTierColor = (tier) => {
        const colors = {
            economy: '#6c757d',
            standard: '#343a40',
            comfort: '#007bff',
            premium: '#6f42c1'
        };
        return colors[tier] || colors.standard;
    };

    // Get icon component
    const getDestinationIcon = (iconName) => {
        const icons = {
            plane: Plane,
            hospital: Building2,
            sun: Sun,
            anchor: Anchor,
            home: Home,
            briefcase: Briefcase,
            dice: Star
        };
        const IconComponent = icons[iconName] || MapPin;
        return <IconComponent size={20} />;
    };

    // Format time
    const formatEta = (seconds) => {
        if (!seconds) return t('eta_unknown');
        if (seconds < 60) return `${seconds}s`;
        return t('eta_minutes', Math.ceil(seconds / 60));
    };

    // Render screens
    const renderHome = () => (
        <div className="screen home-screen">
            <div className="header">
                {headerLogoError ? (
                    <span className="header-logo header-logo-fallback">LAYMO</span>
                ) : (
                    <img
                        src="header-logo.png"
                        alt="Laymo"
                        className="header-logo"
                        onError={() => setHeaderLogoError(true)}
                    />
                )}
                <p className="tagline">{t('tagline')}</p>
            </div>

            <div className="location-card">
                <div className="location-row pickup" onClick={getCurrentLocation}>
                    <div className="location-icon pickup-icon">
                        <div className="dot" />
                    </div>
                    <div className="location-info">
                        <span className="label">{t('pickup')}</span>
                        <span className="value">{pickupStreet || t('tap_set_current_location')}</span>
                    </div>
                    {loading ? <Loader2 className="spinner" size={20} /> : <Navigation size={20} />}
                </div>

                <div className="location-divider" />

                <div className="location-row destination" onClick={() => {
                    if (pickup) {
                        setScreen('selectDestination');
                    } else {
                        getCurrentLocation();
                    }
                }}>
                    <div className="location-icon dest-icon">
                        <MapPin size={16} />
                    </div>
                    <div className="location-info">
                        <span className="label">{t('destination')}</span>
                        <span className="value">{destinationStreet || t('where_to')}</span>
                    </div>
                    <ChevronRight size={20} />
                </div>
            </div>

            <div className="section">
                <h3>{t('quick_destinations')}</h3>
                <div className="destinations-grid">
                    {popularDestinations.slice(0, 4).map((dest) => (
                        <button 
                            key={dest.id} 
                            className="destination-btn"
                            onClick={async () => {
                                if (!pickup) await getCurrentLocation();
                                selectDestination(dest);
                            }}
                        >
                            {getDestinationIcon(dest.icon)}
                            <span>{dest.name}</span>
                        </button>
                    ))}
                </div>
            </div>

            <button 
                className="use-waypoint-btn"
                onClick={async () => {
                    if (!pickup) await getCurrentLocation();
                    await getWaypointDestination();
                    if (destination) setScreen('confirmRide');
                }}
            >
                <MapPin size={20} />
                <span>{t('use_map_waypoint')}</span>
            </button>
        </div>
    );

    const renderSelectDestination = () => (
        <div className="screen select-screen">
            <div className="select-header">
                <button className="back-btn" onClick={() => setScreen('home')}>
                    <X size={24} />
                </button>
                <h2>{t('select_destination')}</h2>
            </div>

            <button 
                className="waypoint-option"
                onClick={async () => {
                    await getWaypointDestination();
                    if (destination) setScreen('confirmRide');
                }}
            >
                <Navigation size={24} />
                <div className="option-text">
                    <span className="option-title">{t('use_map_waypoint')}</span>
                    <span className="option-subtitle">{t('waypoint_subtitle')}</span>
                </div>
                <ChevronRight size={20} />
            </button>

            <div className="section">
                <h3>{t('popular_destinations')}</h3>
                <div className="destinations-list">
                    {popularDestinations.map((dest) => (
                        <button 
                            key={dest.id} 
                            className="destination-item"
                            onClick={() => selectDestination(dest)}
                        >
                            <div className="dest-icon-wrapper">
                                {getDestinationIcon(dest.icon)}
                            </div>
                            <span className="dest-name">{dest.name}</span>
                            <ChevronRight size={18} />
                        </button>
                    ))}
                </div>
            </div>
        </div>
    );

    const renderConfirmRide = () => (
        <div className="screen confirm-screen">
            <div className="confirm-header">
                <button className="back-btn" onClick={() => setScreen('home')}>
                    <X size={24} />
                </button>
                <h2>{t('confirm_ride')}</h2>
            </div>

            <div className="route-summary">
                <div className="route-point">
                    <div className="point-icon pickup-dot" />
                    <div className="point-info">
                        <span className="point-label">{t('pickup')}</span>
                        <span className="point-name">{pickupStreet}</span>
                    </div>
                </div>
                <div className="route-line" />
                <div className="route-point">
                    <div className="point-icon dest-dot">
                        <MapPin size={14} />
                    </div>
                    <div className="point-info">
                        <span className="point-label">{t('destination')}</span>
                        <span className="point-name">{destinationStreet}</span>
                    </div>
                </div>
            </div>

            <div className="tier-selector">
                <h3>{t('select_ride_type')}</h3>
                <div className="tiers">
                    {tiers.map((tier) => (
                        <button
                            key={tier.id}
                            className={`tier-option ${selectedTier === tier.id ? 'selected' : ''}`}
                            onClick={() => handleTierChange(tier.id)}
                            style={{ '--tier-color': getTierColor(tier.id) }}
                        >
                            <Car size={24} />
                            <span className="tier-name">{tier.name}</span>
                            <span className="tier-multiplier">
                                {tier.multiplier < 1 ? '-' : tier.multiplier > 1 ? '+' : ''}
                                {Math.abs((tier.multiplier - 1) * 100).toFixed(0)}%
                            </span>
                        </button>
                    ))}
                </div>
            </div>

            <div className="party-selector">
                <h3>{t('party_size')}</h3>
                <p className="party-hint">{t('party_hint')}</p>
                <div className="party-options">
                    {Array.from({ length: maxPartySize + 1 }, (_, n) => (
                        <button
                            key={n}
                            type="button"
                            className={`party-option ${partySize === n ? 'selected' : ''}`}
                            onClick={() => setPartySize(n)}
                        >
                            {n === 0 ? t('party_just_me') : n === 1 ? t('party_one_other') : t('party_many_others', n)}
                        </button>
                    ))}
                </div>
            </div>

            <div className="hurry-selector">
                <h3>{t('in_a_hurry')}</h3>
                <p className="hurry-hint">{t('hurry_hint')}</p>
                <div className="hurry-options">
                    <button
                        type="button"
                        className={`hurry-option ${!inAHurry ? 'selected' : ''}`}
                        onClick={() => setInAHurry(false)}
                    >
                        <Clock size={22} />
                        <span>{t('hurry_no')}</span>
                    </button>
                    <button
                        type="button"
                        className={`hurry-option ${inAHurry ? 'selected' : ''}`}
                        onClick={() => setInAHurry(true)}
                    >
                        <Zap size={22} />
                        <span>{t('hurry_yes')}</span>
                    </button>
                </div>
            </div>

            {priceEstimate && (
                <div className="estimate-card">
                    <div className="estimate-row">
                        <div className="estimate-item">
                            <DollarSign size={18} />
                            <span className="estimate-value">${priceEstimate.price}</span>
                            <span className="estimate-label">{t('estimated_fare')}</span>
                        </div>
                        <div className="estimate-item">
                            <Clock size={18} />
                            <span className="estimate-value">{formatEta(priceEstimate.eta)}</span>
                            <span className="estimate-label">{t('trip_time')}</span>
                        </div>
                        <div className="estimate-item">
                            <MapPin size={18} />
                            <span className="estimate-value">{priceEstimate.distanceMiles} mi</span>
                            <span className="estimate-label">{t('distance')}</span>
                        </div>
                    </div>
                </div>
            )}

            <button 
                className="confirm-btn"
                onClick={requestRide}
                disabled={loading || !priceEstimate}
            >
                {loading ? (
                    <Loader2 className="spinner" size={20} />
                ) : (
                    <>
                        <span>{t('request_laymo')}</span>
                        {priceEstimate && <span className="btn-price">${priceEstimate.price}</span>}
                    </>
                )}
            </button>
        </div>
    );

    const renderRiding = () => (
        <div className="screen riding-screen">
            <div className="riding-status">
                {rideState === 'waiting' && (
                    <>
                        <Loader2 className="status-icon spinner" size={48} />
                        <h2>{t('finding_ride')}</h2>
                        <p>{t('dispatching_vehicle')}</p>
                    </>
                )}
                
                {rideState === 'arriving' && (
                    <>
                        <Car className="status-icon arriving" size={48} />
                        <h2>{t('ride_on_the_way')}</h2>
                        <p>{rideInfo?.vehicle}</p>
                        <div className="eta-display">
                            <Clock size={20} />
                            <span>{formatEta(eta)} {t('away')}</span>
                        </div>
                    </>
                )}

                {rideState === 'pickup' && (
                    <>
                        <Check className="status-icon arrived" size={48} />
                        <h2>{t('ride_arrived')}</h2>
                        <p>{t('press_e_to_enter')} {rideInfo?.partySize > 0 && t('party_press_e_to_enter')}</p>
                        <div className="driver-info">
                            <span className="driver-name">{rideInfo?.driverName}</span>
                            <span className="vehicle-name">{rideInfo?.vehicle}</span>
                        </div>
                    </>
                )}

                {rideState === 'riding' && (
                    <>
                        <Navigation className="status-icon riding" size={48} />
                        <h2>{t('on_your_way')}</h2>
                        <p>{t('heading_to', destinationStreet)}</p>
                        
                        <div className="trip-progress">
                            <div className="progress-bar">
                                <div 
                                    className="progress-fill" 
                                    style={{ width: `${tripProgress}%` }}
                                />
                            </div>
                            <div className="progress-info">
                                <span>{t('progress_complete', tripProgress)}</span>
                                {eta && <span>{t('eta_remaining', formatEta(eta))}</span>}
                            </div>
                        </div>
                    </>
                )}

                {rideState === 'pulling_over' && (
                    <>
                        <Car className="status-icon" size={48} />
                        <h2>{t('pulling_over')}</h2>
                        <p>{t('can_get_out_when_stopped')}</p>
                    </>
                )}
            </div>

            {rideInfo && (
                <div className="ride-details">
                    <div className="detail-row">
                        <span className="detail-label">{t('estimated_fare')}</span>
                        <span className="detail-value">${rideInfo.price}</span>
                    </div>
                    <div className="detail-row">
                        <span className="detail-label">{t('vehicle')}</span>
                        <span className="detail-value">{rideInfo.vehicle}</span>
                    </div>
                </div>
            )}

            {(rideState === 'waiting' || rideState === 'arriving' || rideState === 'pickup') && (
                <button className="cancel-btn" onClick={cancelRide}>
                    <X size={20} />
                    <span>{t('cancel_ride')}</span>
                </button>
            )}

            {rideState === 'riding' && (
                <button
                    className="end-ride-btn"
                    onClick={() => {
                        if (!devMode && window.setPopUp) {
                            window.setPopUp({
                                title: t('end_ride_title'),
                                description: t('end_ride_description'),
                                buttons: [
                                    { title: t('no'), color: 'blue' },
                                    { title: t('yes_pull_over'), color: 'red', cb: () => fetchNui('endRide') }
                                ]
                            });
                        } else {
                            fetchNui('endRide');
                        }
                    }}
                >
                    <X size={20} />
                    <span>{t('end_ride_get_out')}</span>
                </button>
            )}
        </div>
    );

    const renderCompleted = () => (
        <div className="screen completed-screen">
            <div className="completed-content">
                <div className="completed-icon">
                    <Check size={48} />
                </div>
                <h2>{t('arrived_title')}</h2>
                <p>{t('thanks_riding')}</p>

                <div className="receipt-card">
                    <div className="receipt-header">
                        <span>{t('trip_receipt')}</span>
                    </div>
                    <div className="receipt-row">
                        <span>{t('base_fare')}</span>
                        <span>$50.00</span>
                    </div>
                    <div className="receipt-row">
                        <span>{t('distance')}</span>
                        <span>{priceEstimate?.distanceMiles || '0'} mi</span>
                    </div>
                    <div className="receipt-row total">
                        <span>{t('total')}</span>
                        <span>${rideInfo?.finalPrice || rideInfo?.price || 0}</span>
                    </div>
                </div>

                <div className="rating-section">
                    <p>{t('rate_your_ride')}</p>
                    <div className="stars">
                        {[1, 2, 3, 4, 5].map((value) => (
                            <button
                                key={value}
                                type="button"
                                className={`star-btn ${rating >= value ? 'filled' : ''}`}
                                onClick={async () => {
                                    setRating(value);
                                    if (!devMode) {
                                        await fetchNui('submitRating', { rating: value });
                                    }
                                }}
                                aria-label={`${value} star${value !== 1 ? 's' : ''}`}
                            >
                                <Star size={32} fill={rating >= value ? 'currentColor' : 'none'} />
                            </button>
                        ))}
                    </div>
                    {rating > 0 && <p className="rating-thanks">{t('rating_thanks')}</p>}
                </div>

                <button className="done-btn" onClick={startNewRide}>
                    {t('done')}
                </button>
            </div>
        </div>
    );

    return (
        <AppProvider theme={theme}>
            <div className="app" data-theme={theme}>
                {screen === 'home' && renderHome()}
                {screen === 'selectDestination' && renderSelectDestination()}
                {screen === 'confirmRide' && renderConfirmRide()}
                {screen === 'riding' && renderRiding()}
                {screen === 'completed' && renderCompleted()}
            </div>
        </AppProvider>
    );
};

const AppProvider = ({ children, theme }) => {
    if (devMode) {
        return (
            <div className='dev-wrapper'>
                <Frame theme={theme}>{children}</Frame>
            </div>
        );
    }
    return children;
};

export default App;

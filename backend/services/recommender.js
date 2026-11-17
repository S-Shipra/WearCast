function getTargetWarmth(feelsLike) {
  if (feelsLike > 30) return 1;
  if (feelsLike >= 22) return 2;
  if (feelsLike >= 15) return 3;
  if (feelsLike >= 8)  return 4;
  return 5;
}

function getSleeveLength(item) {
  if (['sleeveless', 'short', 'long', 'unknown'].includes(item.sleeveLength)) {
    return item.sleeveLength;
  }

  // Keep recommendations safe for catalog records created before these tags existed.
  const type = `${item.articleType || ''} ${item.name || ''}`.toLowerCase();
  if (/sleeveless|tank top/.test(type)) return 'sleeveless';
  if (/t-?shirt|\btee\b/.test(type)) return 'short';
  if (/long.?sleeve|\bshirt\b/.test(type)) return 'long';
  return 'not_applicable';
}

function getFabricWeight(item) {
  if (['light', 'midweight', 'heavy', 'unknown'].includes(item.fabricWeight)) {
    return item.fabricWeight;
  }
  if (item.warmthLevel <= 2) return 'light';
  if (item.warmthLevel === 3) return 'midweight';
  if (item.warmthLevel >= 4) return 'heavy';
  return 'not_applicable';
}

function getFootwearCoverage(item) {
  if (['open', 'covered'].includes(item.footwearCoverage)) {
    return item.footwearCoverage;
  }
  const type = `${item.articleType || ''} ${item.name || ''}`.toLowerCase();
  if (/sandal|flip.?flop|slipper|slide/.test(type)) return 'open';
  if (/shoe|boot|sneaker|trainer|loafer/.test(type)) return 'covered';
  return 'not_applicable';
}

function generateOutfits(
  catalog,
  weather,
  userGender = 'unisex',
  occasion = null,
  thermalPreference = 'balanced',
  preferences = {},
) {
  const baseWarmth = getTargetWarmth(weather.feelsLike);
  const preference = ['cold', 'balanced', 'hot'].includes(thermalPreference)
    ? thermalPreference
    : 'balanced';
  const warmthAdjustment = preference === 'cold' ? 1 : preference === 'hot' ? -1 : 0;
  const targetWarmth = Math.max(1, Math.min(5, baseWarmth + warmthAdjustment));
  const isHot = weather.feelsLike >= 28;
  const requiresCoveredFootwear =
    weather.feelsLike <= 18 || (preference === 'cold' && weather.feelsLike <= 22);
  const reasons = [];
  const preferredColors = (preferences.colors || []).map(c => String(c).toLowerCase());
  const preferredStyle = preferences.style || 'any';
  const feedbackScores = new Map();
  for (const entry of preferences.feedback || []) {
    const delta = entry.rating === 'like' ? 1.5 : -1;
    for (const id of entry.itemIds || []) feedbackScores.set(String(id), (feedbackScores.get(String(id)) || 0) + delta);
  }
  
  const needsWaterproof = weather.rainProb > 50;
  const needsUVProtection = weather.uvIndex > 6;
  const needsWindbreaker = weather.windSpeed > 25;
  const needsBreathable = weather.humidity > 80;

  if (needsWaterproof) reasons.push("Rain expected, so waterproof items are preferred");
  if (needsUVProtection) reasons.push("High UV, so sunglasses/caps are recommended");
  if (needsWindbreaker) reasons.push("Windy conditions, outerwear is recommended");
  if (needsBreathable) reasons.push("High humidity, breathable fabric is preferred");
  if (isHot) reasons.push("Hot conditions, so light short-sleeved tops are prioritized");
  if (requiresCoveredFootwear) reasons.push("Cool conditions, so covered footwear is required");
  if (preference === 'cold') reasons.push("Your preference adds warmth and layering");
  if (preference === 'hot') reasons.push("Your preference favors lighter-feeling pieces");
  if (occasion) reasons.push(`Filtered specifically for ${occasion} wear`);
  if (preferredStyle !== 'any') reasons.push(`Your ${preferredStyle} style preference is included`);
  if (preferredColors.length) reasons.push(`Prioritized your colors: ${preferredColors.join(', ')}`);

  const validGender = ['unisex', userGender.toLowerCase()];
  
  const findBest = (category, usedItemIds, isOptional = false) => {
    // Apply weather rules before scoring or fallback. Fallback may relax warmth,
    // but it must never bring back an item that violates these rules.
    const eligibleItems = catalog.filter(i => {
      if (
        i.category !== category ||
        !validGender.includes(i.gender) ||
        usedItemIds.has(String(i._id))
      ) return false;

      if (isHot && category === 'top') {
        const sleeveLength = getSleeveLength(i);
        const fabricWeight = getFabricWeight(i);
        if (!['sleeveless', 'short'].includes(sleeveLength) || fabricWeight !== 'light') {
          return false;
        }
      }

      if (
        requiresCoveredFootwear &&
        category === 'footwear' &&
        getFootwearCoverage(i) !== 'covered'
      ) return false;

      return true;
    });

    // 1. Prefer items within one warmth level of the target.
    let items = eligibleItems.filter(i =>
      Math.abs(i.warmthLevel - targetWarmth) <= 1
    );

    // 2. If needed, relax warmth only within the weather-safe candidate set.
    if (items.length === 0) items = eligibleItems;

    // 3. Apply Occasion Filter if selected
    if (occasion) {
      const occasionFiltered = items.filter(i => i.occasion === occasion);
      // If we have occasion-specific items, use them. Otherwise, keep all.
      if (occasionFiltered.length > 0) items = occasionFiltered;
    }

    if (items.length === 0 && isOptional) return null;
    if (items.length === 0) return null;

    items = items.map(item => {
      let score = 10 - Math.abs(item.warmthLevel - targetWarmth); 
      if (isHot && category === 'top' && getFabricWeight(item) === 'light') score += 2;
      if (requiresCoveredFootwear && category === 'footwear') score += 2;
      if (needsWaterproof && item.waterproof) score += 5;
      if (needsBreathable && item.breathable) score += 3;
      if (preferredColors.some(color => String(item.color || '').toLowerCase().includes(color))) score += 2.5;
      if (item.ownerId) score += 4;
      const styleOccasion = preferredStyle === 'any' ? null : preferredStyle[0].toUpperCase() + preferredStyle.slice(1);
      if (styleOccasion && item.occasion === styleOccasion) score += 2;
      score += feedbackScores.get(String(item._id)) || 0;
      score += Math.random() * 5; // Randomness for shuffle
      return { item, score };
    });

    items.sort((a, b) => b.score - a.score);
    return items[0].item; 
  };

  const outfits = [];
  const previouslyRecommended = new Set();
  
  for (let i = 0; i < 3; i++) {
    const usedItemIds = new Set(previouslyRecommended);
    const pick = (category, optional = false) => {
      const item = findBest(category, usedItemIds, optional);
      if (item) usedItemIds.add(String(item._id));
      return item;
    };
    const top = pick('top');
    const bottom = pick('bottom');
    const footwear = pick('footwear');
    const outerwear = targetWarmth >= 4 ? pick('outerwear', true) : null;
    const accessory = (needsUVProtection || needsWaterproof || occasion === 'Formal') ? pick('accessory', true) : null;

    if (top && bottom && footwear) {
      const outfitItems = [top, bottom, footwear];
      if (outerwear) outfitItems.push(outerwear);
      if (accessory) outfitItems.push(accessory);

      outfits.push({
        items: outfitItems,
        explanation: generateExplanation(targetWarmth, weather, reasons, outfitItems, preferredColors, preferredStyle),
        itemReasons: Object.fromEntries(outfitItems.map(item => [String(item._id), explainItem(item, weather, targetWarmth, preferredColors)]))
      });
      outfitItems.forEach((item) => previouslyRecommended.add(String(item._id)));
    }
  }

  return outfits;
}

function explainItem(item, weather, targetWarmth, preferredColors) {
  const reasons = [];
  if (Math.abs(item.warmthLevel - targetWarmth) <= 1) reasons.push('its warmth suits the current conditions');
  if (weather.feelsLike >= 28 && item.category === 'top') reasons.push('it is a light option for the heat');
  if (weather.feelsLike <= 18 && item.category === 'footwear') reasons.push('it provides covered footwear in cool weather');
  if (weather.rainProb > 50 && item.waterproof) reasons.push('it helps with expected rain');
  if (weather.humidity > 80 && item.breathable) reasons.push('its breathable fabric suits the humidity');
  if (preferredColors.some(color => String(item.color || '').toLowerCase().includes(color))) reasons.push('it matches a color you prefer');
  if (item.ownerId) reasons.push('it comes from your wardrobe');
  return reasons.length ? `${item.name}: ${reasons.join(' and ')}.` : `${item.name}: selected to complete a weather-appropriate outfit.`;
}

function generateExplanation(targetWarmth, weather, modifierReasons, items, preferredColors, preferredStyle) {
  let text = `It feels like ${weather.feelsLike}°C outside. `;
  text += `We chose warmth level ${targetWarmth} clothing. `;
  
  if (modifierReasons.length > 0) {
    text += modifierReasons.join(". ") + ". ";
  } else {
    text += "Conditions are clear and comfortable. ";
  }
  const colors = [...new Set(items.map(item => String(item.color || '').toLowerCase()))];
  if (preferredColors.length && colors.some(color => preferredColors.some(pref => color.includes(pref)))) text += ' The outfit includes colors from your preferences.';
  if (preferredStyle !== 'any') text += ` It also reflects your ${preferredStyle} style preference.`;
  if (items.some(item => item.ownerId)) text += ' Personal wardrobe pieces are prioritized when they fit the conditions.';
  
  return text;
}

module.exports = { generateOutfits };

function getTargetWarmth(feelsLike) {
  if (feelsLike > 30) return 1;
  if (feelsLike >= 22) return 2;
  if (feelsLike >= 15) return 3;
  if (feelsLike >= 8)  return 4;
  return 5;
}

function generateOutfits(catalog, weather, userGender = 'unisex', occasion = null) {
  const targetWarmth = getTargetWarmth(weather.feelsLike);
  const reasons = [];
  
  const needsWaterproof = weather.rainProb > 50;
  const needsUVProtection = weather.uvIndex > 6;
  const needsWindbreaker = weather.windSpeed > 25;
  const needsBreathable = weather.humidity > 80;

  if (needsWaterproof) reasons.push("Rain expected, so waterproof items are preferred");
  if (needsUVProtection) reasons.push("High UV, so sunglasses/caps are recommended");
  if (needsWindbreaker) reasons.push("Windy conditions, outerwear is recommended");
  if (needsBreathable) reasons.push("High humidity, breathable fabric is preferred");
  if (occasion) reasons.push(`Filtered specifically for ${occasion} wear`);

  const validGender = ['unisex', userGender.toLowerCase()];
  
  const findBest = (category, isOptional = false) => {
    // 1. Try to find items matching the target warmth (+/- 1)
    let items = catalog.filter(i => 
      i.category === category && 
      validGender.includes(i.gender) &&
      Math.abs(i.warmthLevel - targetWarmth) <= 1 
    );

    // 2. FALLBACK: If nothing is found, get any item in that category
    if (items.length === 0) {
      items = catalog.filter(i => 
        i.category === category && 
        validGender.includes(i.gender)
      );
    }

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
      if (needsWaterproof && item.waterproof) score += 5;
      if (needsBreathable && item.breathable) score += 3;
      score += Math.random() * 5; // Randomness for shuffle
      return { item, score };
    });

    items.sort((a, b) => b.score - a.score);
    return items[0].item; 
  };

  const outfits = [];
  
  for (let i = 0; i < 3; i++) {
    const top = findBest('top');
    const bottom = findBest('bottom');
    const footwear = findBest('footwear');
    const outerwear = targetWarmth >= 4 ? findBest('outerwear', true) : null;
    const accessory = (needsUVProtection || needsWaterproof || occasion === 'Formal') ? findBest('accessory', true) : null;

    if (top && bottom && footwear) {
      const outfitItems = [top, bottom, footwear];
      if (outerwear) outfitItems.push(outerwear);
      if (accessory) outfitItems.push(accessory);

      outfits.push({
        items: outfitItems,
        explanation: generateExplanation(targetWarmth, weather, reasons)
      });
    }
  }

  return outfits;
}

function generateExplanation(targetWarmth, weather, modifierReasons) {
  let text = `It feels like ${weather.feelsLike}°C outside. `;
  text += `We chose warmth level ${targetWarmth} clothing. `;
  
  if (modifierReasons.length > 0) {
    text += modifierReasons.join(". ") + ". ";
  } else {
    text += "Conditions are clear and comfortable. ";
  }
  
  return text;
}

module.exports = { generateOutfits };
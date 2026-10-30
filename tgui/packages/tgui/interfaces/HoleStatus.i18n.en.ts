const formatTime = (seconds: number): string => {
  if (seconds <= 0) {
    return '0 sec.';
  }
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = Math.round(seconds % 60);
  if (minutes > 0) {
    return `${minutes} min. ${remainingSeconds} sec.`;
  }
  return `${remainingSeconds} sec.`;
};

export default {
  windowTitle: 'View holes',
  emptyState: 'Nothing to feel down there.',
  tabs: {
    status: 'Status',
    settings: 'Settings',
    genetics: 'Genetics',
  },
  cards: {
    front: 'Front',
    rear: 'Rear',
    stomach: 'Stomach',
    ovipositor: 'Ovipositor',
    womb: 'Womb',
  },
  wear: {
    title: 'Wear and tear',
    tightness: 'Tightness',
    feels: 'Feels',
    lube: 'Lube',
    soreness: 'Soreness',
    fine: 'fine',
    gaping: 'Gaping open',
    gapingSoon: 'About to gape',
    tightnessWords: {
      'Virgin-tight': 'virgin-tight',
      Tight: 'tight',
      Average: 'average',
      Relaxed: 'relaxed',
      Loose: 'loose',
      Gaped: 'gaped',
    },
    stretchWords: {
      gaping: 'gaping open',
      wide: 'stretched wide',
      loosened: 'loosened',
      tight: 'tight',
      loose: 'loose',
      snug: 'snug',
    },
    lubeWords: {
      slick: 'slick',
      damp: 'damp',
      dry: 'dry',
    },
    sorenessWords: {
      sore: 'sore',
      raw: 'chafed raw',
      overused: 'used past bearing',
    },
  },
  fill: {
    title: 'Fill',
    empty: 'empty',
    mostly: 'mostly',
    seed: 'seed',
    own: 'own',
    holdingIn: 'Holding it in',
  },
  items: {
    title: 'Inside',
    none: 'nothing',
    outer: 'At the opening',
    inner: 'Inside',
    deep: 'Deep inside',
    stuck: 'stuck',
    takeOut: 'Take out',
    pushDeeper: 'Push deeper',
    insert: 'Work in',
    holding: 'In hand',
    fit: 'fit',
    seconds: 's',
    failChance: 'may fail',
  },
  womb: {
    fertile: 'Fertile',
    sterile: 'Sterile',
    contraceptive: 'under a contraceptive',
    pregnancy: 'Pregnancy',
    stage: 'belly stage',
    seed: 'Seed inside',
    passageEggs: 'Eggs lodged in the passage',
    labour: 'In labour',
    contraction: 'contraction',
    pushing: 'pushing',
  },
  labels: {
    organ: 'ORGAN',
    eggsInside: 'EGGS INSIDE',
    stored: 'Stored',
    clutch: 'Clutch',
    capacity: 'Capacity',
    color: 'Color',
    type: 'Type',
    name: 'Name',
    description: 'Description',
    organDescription: 'Organ description',
    nutrients: 'Nutrients',
    nutrientCost: 'Cost',
    interval: 'Interval',
    resourceDependent: 'Resource Dep',
    limit: 'Limit',
    production: 'Production',
    nextEgg: 'Next egg',
    hatchlingsInside: 'Hatchlings inside',
    stage: 'Stage',
    scale: 'Size',
    traits: 'Traits',
    preview: 'Preview',
    parents: 'Parents',
    mother: 'Mother',
    father: 'Father',
    unknown: 'Unknown',
    defaultColor: 'Default',
    fertilized: 'Fertilized',
    unfertilized: 'Unfertilized',
    by: 'by',
    autoHatch: 'Auto Hatch',
    internalBirth: 'Internal Birth',
    willHatchInside: 'Will hatch inside carrier.',
    extract: 'Push out',
    extractAll: 'Push out all',
    layEggs: 'Lay eggs',
    edit: 'Edit',
    pickColor: 'Pick color',
    apply: 'Apply',
    reset: 'Reset',
    profileDefault: 'Profile',
    on: 'ON',
    off: 'OFF',
    active: 'Active',
    inactive: 'Inactive',
    yes: 'Yes',
    no: 'No',
    unknownStage: '-',
  },
  organNames: {
    ovipositor: 'OVIPOSITOR',
    womb: 'WOMB',
    anus: 'ANUS',
    guts: 'GUTS',
  },
  eggTypes: {
    Hardshell: 'Hardshell',
    Avian: 'Avian',
    Softshell: 'Softshell',
    Parasitic: 'Parasitic',
    Spider: 'Spider',
    'Bog Bug': 'Bog Bug',
    Harpy: 'Harpy',
    Embryo: 'Hatchling',
  },
  traitNames: {
    Aphrodisiac: 'Aphrodisiac',
    Poison: 'Poison',
    Parasite: 'Parasite',
    Accelerated: 'Accelerated',
    aphrodisiac: 'Aphrodisiac',
    poison: 'Poison',
    parasite: 'Parasite',
    fast_growth: 'Accelerated',
  },
  formatTime,
  formatFill: (volume: number, capacity: number): string =>
    `${volume} / ${capacity} u`,
  formatStage: (stage: number, maxStage: number): string =>
    `${stage} of ${maxStage}`,
  formatStatus: (status: string, timeLeft: number): string => {
    if (status === 'ready') {
      return 'Ready.';
    }
    if (status === 'growing') {
      if (timeLeft > 0) {
        return `Ready in ${formatTime(timeLeft)}.`;
      }
      return 'Growing.';
    }
    return 'Dormant.';
  },
};

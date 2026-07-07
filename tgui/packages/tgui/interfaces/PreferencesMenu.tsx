import { Fragment, useEffect, useRef, useState } from 'react';
import {
  Box,
  Button,
  ByondUi,
  Dropdown,
  Icon,
  Input,
  Section,
  Stack,
  Tabs,
  Tooltip,
} from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Booleanish = boolean | number;

type LoadoutSlot = {
  slot: number;
  name: string;
};

type SpeciesStat = {
  name: string;
  label: string;
  value: number;
};

type SpeciesEntry = {
  id: string;
  name: string;
  description: string;
  available: Booleanish;
  lock_reason: string;
  language: string;
  ancestry_label: string;
  ages: string;
  tags: string[];
  tag_descriptions?: Record<string, string>;
  stats: SpeciesStat[];
};

type PatronEntry = {
  id: string;
  name: string;
  domain: string;
  description: string;
  flaws: string;
  worshippers: string;
  sins: string;
  boons: string;
  available: Booleanish;
  selected: Booleanish;
};

type FaithEntry = {
  id: string;
  name: string;
  description: string;
  available: Booleanish;
  selected: Booleanish;
  patrons: PatronEntry[];
};

type AncestryOption = {
  name: string;
  value: string;
  color: string;
  selected: Booleanish;
};

type ErpFlag = {
  name: string;
  bit: number;
  description: string;
  on: Booleanish;
};

type ErpPrefEntry = {
  type: string;
  name: string;
  description: string;
  kind: 'bool' | 'flags' | 'number' | 'choice';
  value?: unknown;
  flags?: ErpFlag[];
  min?: number;
  max?: number;
  choices?: string[];
};

type ErpCategory = {
  name: string;
  prefs: ErpPrefEntry[];
};

type ErpKink = {
  name: string;
  description: string;
  enabled: Booleanish;
  intensity: number;
  notes: string;
};

type ErpKinkCategory = {
  name: string;
  kinks: ErpKink[];
};

type FeatureOption = {
  name: string;
  value: string;
  thumb?: string;
  coverage?: string;
};

type FeatureColor = {
  name: string;
  value: string;
  index: string;
};

type FeatureExtra = {
  task: string;
  label: string;
  kind: 'color' | 'text';
  value: string;
};

type FeatureEntry = {
  key: string;
  name: string;
  enabled: Booleanish;
  can_disable: Booleanish;
  choice_name: string;
  choice_value?: string;
  choice_options?: FeatureOption[];
  accessory_name?: string;
  accessory_value?: string;
  accessory_options?: FeatureOption[];
  colors?: FeatureColor[];
  extras?: FeatureExtra[];
  erp?: Booleanish;
  section?: string;
};

type SmallclothesOption = {
  name: string;
  value: string;
  thumb?: string;
};

type SmallclothesCatalogEntry = {
  id: string;
  name: string;
  options: SmallclothesOption[];
};

type SmallclothesEntry = {
  id: string;
  value: string;
  name: string;
  color: string | null;
};

type PrefsData = {
  real_name: string;
  initial_tab: string;
  open_sequence: number;
  preferences_fullscreen: Booleanish;
  preferences_scale: number;
  species_id: string;
  species_name: string;
  species_options: SpeciesEntry[];
  is_taur: Booleanish;
  taur_body: string;
  taur_color: string;
  taur_markings: string;
  taur_tertiary: string;
  gender: string;
  gender_short: string;
  default_slot: number;
  patron_name: string;
  faith_name: string;
  selected_patron_id: string;
  selected_faith_id: string;
  faith_options: FaithEntry[];
  high_job: string;
  age: string;
  age_index: number;
  age_min: number;
  age_max: number;
  age_options: string[];
  age_tooltips: Record<string, string>;
  pronouns: string;
  domhand: string;
  ancestry_label: string;
  ancestry_value: string;
  ancestry_options: AncestryOption[];
  erp: {
    lock_reason: string | null;
    categories: ErpCategory[];
    kink_categories: ErpKinkCategory[];
  };
  genital_set_label: string;
  genital_extra_unlock: Booleanish;
  headshot: string | null;
  nsfw_headshot: string | null;
  features: FeatureEntry[];
  smallclothes_catalog: SmallclothesCatalogEntry[];
  smallclothes: {
    random: Booleanish;
    entries: SmallclothesEntry[];
  };
  mutant_colors: { slot: number; color: string }[];
  use_skintones: Booleanish;
  use_titles: Booleanish;
  race_title: string;
  combat_music: string;
  defeat_mode: string;
  defeat_threshold: number;
  song_set: Booleanish;
  song_title: string;
  song_artist: string;
  preview_underwear: Booleanish;
  preview_clothes: Booleanish;
  preview_dir: number;
  background: string;
  background_options: FeatureOption[];
  thumbs?: Record<string, string>;
  preview_map: string | null;
  preview_map_front: string | null;
  preview_map_side: string | null;
  preview_bbox_w: number;
  preview_bbox_h: number;
  culture_name: string;
  voice_type: string;
  voice_color: string;
  voice_pack: string;
  moan_selection: string;
  selected_accent: string;
  loadouts: LoadoutSlot[];
  triumphs: number;
  round_start_status: string;
  round_start_seconds: number;
  round_ready_players: number;
  round_total_players: number;
  round_player_ready: Booleanish;
  round_action_label: string;
  round_action_icon: string;
  round_action_color: string | null;
  round_action_disabled: Booleanish;
  round_action_tooltip: string;
  game_prefs: {
    hotkeys: Booleanish;
    buttons_locked: Booleanish;
    see_chat_non_mob: Booleanish;
    tgui_fancy: Booleanish;
    tgui_lock: Booleanish;
    windowflashing: Booleanish;
    lobby_music: Booleanish;
    hear_midis: Booleanish;
    ambientocclusion: Booleanish;
    auto_fit_viewport: Booleanish;
    widescreenpref: Booleanish;
    allow_midround_antag: Booleanish;
    pixel_size: string;
    scaling_method: string;
  };
};

const charSections = [
  { id: 'identity', label: 'Identity', icon: 'id-card' },
  { id: 'appearance', label: 'Appearance', icon: 'palette' },
  { id: 'gameplay', label: 'Gameplay', icon: 'gamepad' },
  { id: 'profile', label: 'Character Profile', icon: 'image' },
];

const systemSections = [
  { id: 'erp', label: 'Intimacy', icon: 'heart' },
  { id: 'settings', label: 'Settings', icon: 'cog' },
];


const UNDERWEAR_KEY = '__underwear__';
const FACE_KEY = '__face__';
const TAUR_KEY = '__taur__';
const BACKDROP_KEY = '__backdrop__';
const BODY_KEY = '__body__';
const GENITALS_KEY = '__genitals__';

const FACE_PATTERNS = ['face_detail', 'eyes', 'facial_hair'];
const isFaceFeature = (key: string) =>
  FACE_PATTERNS.some((pattern) => key.includes(pattern));

const asBool = (value: Booleanish | undefined) => value === true || value === 1;

const display = (value: unknown, fallback = 'None') => {
  const text = String(value ?? '').trim();
  return text || fallback;
};

const swatchColor = (value: string) => {
  const text = String(value || '').trim();
  if (!text) {
    return '#888888';
  }
  return text.startsWith('#') ? text : `#${text}`;
};

const clampMenuScale = (value: unknown) => {
  const scale = Number(value);
  if (!Number.isFinite(scale)) {
    return 1;
  }
  return Math.max(0.8, Math.min(1.25, Math.round(scale * 20) / 20));
};

const formatRoundCountdown = (seconds: number) => {
  if (!Number.isFinite(seconds) || seconds < 0) {
    return 'DELAYED';
  }
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  if (minutes <= 0) {
    return `${remainder}s`;
  }
  return `${minutes}:${String(remainder).padStart(2, '0')}`;
};

type PanelProps = {
  title: string;
  icon?: string;
  buttons?: React.ReactNode;
  children?: React.ReactNode;
};

const Panel = (props: PanelProps) => {
  const { title, icon, buttons, children } = props;
  return (
    <Section
      mb={1}
      title={
        <Stack align="center">
          {icon ? (
            <Stack.Item>
              <Icon name={icon} />
            </Stack.Item>
          ) : null}
          <Stack.Item>{title}</Stack.Item>
        </Stack>
      }
      buttons={buttons}
    >
      {children}
    </Section>
  );
};

type PrefRowProps = {
  icon: string;
  label: string;
  value?: unknown;
  onClick?: () => void;
  disabled?: boolean;
  selected?: boolean;
  swatch?: string;
  tooltip?: string;
};

const PrefRow = (props: PrefRowProps) => {
  const { icon, label, value, onClick, disabled, selected, swatch, tooltip } =
    props;
  return (
    <Button
      fluid
      mb={0.5}
      disabled={disabled}
      selected={selected}
      tooltip={tooltip || label}
      onClick={onClick}
    >
      <Stack align="center">
        <Stack.Item>
          <Icon name={icon} />
        </Stack.Item>
        <Stack.Item grow>
          <Box textAlign="left">{label}</Box>
        </Stack.Item>
        {swatch ? (
          <Stack.Item>
            <Box
              width="12px"
              height="12px"
              style={{ border: '1px solid rgba(0,0,0,0.6)' }}
              backgroundColor={swatchColor(swatch)}
            />
          </Stack.Item>
        ) : null}
        <Stack.Item>
          <Box bold>{display(value)}</Box>
        </Stack.Item>
      </Stack>
    </Button>
  );
};

const InfoRow = (props: {
  icon: string;
  label: string;
  value?: unknown;
  valueColor?: string;
}) => {
  const { icon, label, value, valueColor } = props;
  return (
    <Box mb={0.5} p={0.5}>
      <Stack align="center">
        <Stack.Item>
          <Icon name={icon} />
        </Stack.Item>
        <Stack.Item grow>
          <Box textAlign="left">{label}</Box>
        </Stack.Item>
        <Stack.Item>
          <Box bold color={valueColor}>
            {display(value)}
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const ActionButton = (props: {
  icon: string;
  label: string;
  onClick?: () => void;
  color?: string;
  disabled?: boolean;
  selected?: boolean;
}) => {
  const { icon, label, onClick, color, disabled, selected } = props;
  return (
    <Button
      fluid
      mb={0.5}
      textAlign="center"
      icon={icon}
      color={color || undefined}
      disabled={disabled}
      selected={selected}
      tooltip={label}
      onClick={onClick}
    >
      {label}
    </Button>
  );
};

const OptionGrid = (props: {
  options: FeatureOption[];
  selected?: string;
  onSelect: (value: string) => void;
  onHover?: (value: string | null) => void;
  thumbs?: Record<string, string>;
  labelSize?: string;
}) => {
  const { options, selected, onSelect, onHover, thumbs, labelSize } = props;
  const thumbOf = (option: FeatureOption) =>
    option.thumb || thumbs?.[option.value];
  const hasThumbs = options.some((option) => thumbOf(option));
  const optionLabelSize = labelSize || (hasThumbs ? '10px' : '11px');
  return (
    <Box style={{ display: 'flex', flexWrap: 'wrap' }}>
      {options.map((option) => {
        const thumb = thumbOf(option);
        return (
          <Button
            key={option.value}
            mr={0.5}
            mb={0.5}
            tooltip={
              option.coverage
                ? `${option.name} - covers ${option.coverage}`
                : option.name
            }
            selected={String(selected) === String(option.value)}
            onClick={() => onSelect(option.value)}
            onMouseOver={() => onHover?.(option.value)}
            onMouseLeave={() => onHover?.(null)}
            style={
              hasThumbs
                ? { width: '66px', height: '80px', padding: '2px' }
                : undefined
            }
          >
            {hasThumbs ? (
              <Box
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  height: '50px',
                }}
              >
                {thumb ? (
                  thumb.startsWith('data:') ? (
                    <img
                      src={thumb}
                      alt=""
                      style={{
                        width: '50px',
                        height: '50px',
                        objectFit: 'contain',
                        imageRendering: 'pixelated',
                      }}
                    />
                  ) : (
                    <Box
                      className={`character_setup_chargen48x48 ${thumb}`}
                      style={{
                        width: '48px',
                        height: '48px',
                        imageRendering: 'pixelated',
                      }}
                    />
                  )
                ) : (
                  <Icon name="ban" color="label" />
                )}
              </Box>
            ) : null}
            <Box
              style={{
                fontSize: optionLabelSize,
                lineHeight: '1.15',
                overflow: 'hidden',
                whiteSpace: 'nowrap',
                textOverflow: 'ellipsis',
                textAlign: 'center',
              }}
            >
              {option.name}
            </Box>
          </Button>
        );
      })}
    </Box>
  );
};

const FieldBlock = (props: {
  label: string;
  children: React.ReactNode;
  labelSize?: string;
}) => (
  <Box mb={1}>
    <Box
      color="label"
      mb={0.5}
      style={{ fontSize: props.labelSize || '12px', lineHeight: '1.2' }}
    >
      {props.label}
    </Box>
    {props.children}
  </Box>
);

export const PreferencesMenu = () => {
  const { act, data } = useBackend<PrefsData>();

  const mapTab = (tab: string) => (tab === 'game' ? 'settings' : 'identity');
  const [menuScale, setMenuScaleState] = useState(
    clampMenuScale(data.preferences_scale),
  );
  const isFullscreen = asBool(data.preferences_fullscreen);
  const windowWidth = isFullscreen ? 7680 : 1320;
  const windowHeight = isFullscreen ? 4320 : 880;
  const scaledContentStyle =
    menuScale === 1
      ? undefined
      : {
          transform: `scale(${menuScale})`,
          transformOrigin: 'top left',
          width: `${100 / menuScale}%`,
          height: `${100 / menuScale}%`,
        };

  const [activeSection, setActiveSection] = useState(mapTab(data.initial_tab));
  const [activeFeature, setActiveFeature] = useState<string>(UNDERWEAR_KEY);
  const [speciesFilter, setSpeciesFilter] = useState<
    'all' | 'available' | 'locked'
  >('all');
  const [selectionMode, setSelectionMode] = useState<
    'species' | 'faith' | 'ancestry'
  >('species');
  const [speciesSearch, setSpeciesSearch] = useState('');
  const [previewSpeciesId, setPreviewSpeciesId] = useState<string | null>(null);
  const [previewFaithId, setPreviewFaithId] = useState<string | null>(null);
  const hoverTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const dollBoxRef = useRef<HTMLDivElement>(null);
  const frontBoxRef = useRef<HTMLDivElement>(null);
  const sideBoxRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setActiveSection(mapTab(data.initial_tab));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data.open_sequence]);

  useEffect(() => {
    setPreviewSpeciesId(data.species_id || null);
  }, [data.open_sequence, data.species_id]);

  useEffect(() => {
    setPreviewFaithId(data.selected_faith_id || null);
  }, [data.open_sequence, data.selected_faith_id]);

  useEffect(() => {
    const timers = [200, 600, 1500].map((delay) =>
      setTimeout(() => window.dispatchEvent(new Event('resize')), delay),
    );
    return () => timers.forEach(clearTimeout);
  }, [data.preview_map, data.preview_map_front, data.preview_map_side, menuScale, data.preferences_fullscreen]);

  const [previewBoxPx, setPreviewBoxPx] = useState({
    main: 0,
    mainH: 0,
    mini: 0,
  });

  useEffect(() => {
    const measure = () => {
      const dpr = window.devicePixelRatio || 1;
      const mainRect = dollBoxRef.current?.getBoundingClientRect();
      const main = Math.floor((mainRect?.width ?? 0) * dpr);
      const mainH = Math.floor((mainRect?.height ?? 0) * dpr);
      const mini = Math.floor(
        (frontBoxRef.current?.getBoundingClientRect().width ?? 0) * dpr,
      );
      setPreviewBoxPx((prev) =>
        prev.main === main && prev.mainH === mainH && prev.mini === mini
          ? prev
          : { main, mainH, mini },
      );
    };
    measure();
    const timers = [250, 700, 1600].map((delay) => setTimeout(measure, delay));
    window.addEventListener('resize', measure);
    return () => {
      timers.forEach(clearTimeout);
      window.removeEventListener('resize', measure);
    };
  }, [data.preview_map, menuScale, data.preferences_fullscreen]);

  const previewBboxW = Math.max(16, Number(data.preview_bbox_w) || 0);
  const previewBboxH = Math.max(16, Number(data.preview_bbox_h) || 0);
  const previewZoomFor = (boxW: number, boxH: number) =>
    boxW && boxH
      ? Math.max(
          1,
          Math.floor(
            Math.min((boxW * 0.95) / previewBboxW, (boxH * 0.85) / previewBboxH),
          ),
        )
      : 0;
  const previewZoom = previewZoomFor(previewBoxPx.main, previewBoxPx.mainH);
  const previewMiniZoom = previewZoomFor(previewBoxPx.mini, previewBoxPx.mini);

  useEffect(() => {
    const report = () => {
      const m = dollBoxRef.current?.getBoundingClientRect();
      const f = frontBoxRef.current?.getBoundingClientRect();
      const s = sideBoxRef.current?.getBoundingClientRect();
      act('pref', {
        preference: 'character_setup_report_geometry',
        main_w: Math.round(m?.width ?? 0),
        main_h: Math.round(m?.height ?? 0),
        front_w: Math.round(f?.width ?? 0),
        front_h: Math.round(f?.height ?? 0),
        side_w: Math.round(s?.width ?? 0),
        side_h: Math.round(s?.height ?? 0),
        win_w: Math.round(window.innerWidth),
        win_h: Math.round(window.innerHeight),
        dpr: window.devicePixelRatio,
        menu_scale: menuScale,
        zoom_main: previewZoom,
        zoom_mini: previewMiniZoom,
        bbox: `${data.preview_bbox_w}x${data.preview_bbox_h}`,
      });
    };
    const t = setTimeout(report, 250);
    return () => clearTimeout(t);
  }, [data.preview_map, menuScale, data.preferences_fullscreen, previewZoom, previewMiniZoom]);

  const [localRoundSeconds, setLocalRoundSeconds] = useState<number>(-1);

  useEffect(() => {
    setLocalRoundSeconds(Number(data.round_start_seconds ?? -1));
  }, [data.round_start_seconds]);

  useEffect(() => {
    if (localRoundSeconds <= 0) {
      return;
    }
    const timer = setTimeout(
      () => setLocalRoundSeconds(localRoundSeconds - 1),
      1000,
    );
    return () => clearTimeout(timer);
  }, [localRoundSeconds]);

  const ageOptions = data.age_options ?? [];
  const backdropColor =
    data.background === 'white'
      ? '#d8d8d8'
      : data.background === 'dark'
        ? '#0a0a0a'
        : undefined;

  const doPref = (
    preference: string,
    task?: string,
    extra?: Record<string, unknown>,
  ) => {
    act('pref', {
      preference,
      ...(task ? { task } : {}),
      ...(extra || {}),
    });
  };

  const setMenuScale = (scale: number) => {
    const clamped = clampMenuScale(scale);
    setMenuScaleState(clamped); // apply instantly so the screen doesn't jerk
    doPref('character_setup_preferences_scale', undefined, {
      scale: clamped,
    });
  };

  const customizerAct = (
    key: string,
    task: string,
    extra?: Record<string, unknown>,
  ) => {
    doPref('character_setup_customizer', undefined, {
      customizer: key,
      customizer_task: task,
      ...(extra || {}),
    });
  };

  const requestHover = (
    value: string | null,
    color?: string,
    customizer?: string,
  ) => {
    if (hoverTimer.current) {
      clearTimeout(hoverTimer.current);
      hoverTimer.current = null;
    }
    hoverTimer.current = setTimeout(
      () => {
        doPref('character_setup_hover', undefined, {
          acc: value || '',
          color: value ? color || '' : '',
          customizer: value ? customizer || '' : '',
        });
      },
      value ? 180 : 260,
    );
  };

  const headerMeta = [
    data.species_name,
    data.gender,
    `Slot ${display(data.default_slot, '1')}`,
  ]
    .filter(Boolean)
    .join('  /  ');
  const roundStatus = display(data.round_start_status, 'Unknown');
  const roundSeconds = localRoundSeconds;
  const roundCountdown =
    roundStatus === 'Round Started' || roundStatus === 'Setting Up'
      ? roundStatus
      : formatRoundCountdown(roundSeconds);
  const roundStatusColor =
    roundStatus === 'Delayed'
      ? 'bad'
      : roundStatus === 'Starts In'
        ? 'good'
        : 'average';

  // ---- Detail panels ----

  const SelectionModeButtons = () => (
    <Box>
      <Button
        compact
        icon="users"
        selected={selectionMode === 'species'}
        onClick={() => setSelectionMode('species')}
      >
        Species
      </Button>
      <Button
        compact
        icon="asterisk"
        selected={selectionMode === 'faith'}
        onClick={() => setSelectionMode('faith')}
      >
        Faith
      </Button>
      <Button
        compact
        icon="leaf"
        selected={selectionMode === 'ancestry'}
        onClick={() => setSelectionMode('ancestry')}
      >
        {display(data.ancestry_label, 'Ancestry')}
      </Button>
    </Box>
  );

  const renderSpeciesPicker = () => {
    const speciesOptions = data.species_options ?? [];
    const currentSpecies =
      speciesOptions.find((species) => species.id === data.species_id) ||
      speciesOptions.find((species) => species.name === data.species_name);
    const inspectedSpecies =
      speciesOptions.find((species) => species.id === previewSpeciesId) ||
      currentSpecies ||
      speciesOptions[0];
    const search = speciesSearch.trim().toLowerCase();
    const filteredSpecies = speciesOptions
      .filter((species) => {
        const available = asBool(species.available);
        if (speciesFilter === 'available' && !available) {
          return false;
        }
        if (speciesFilter === 'locked' && available) {
          return false;
        }
        if (!search) {
          return true;
        }
        return (
          species.name.toLowerCase().includes(search) ||
          species.id.toLowerCase().includes(search) ||
          (species.tags || []).some((tag) => tag.toLowerCase().includes(search))
        );
      })
      .sort((left, right) => {
        const availableDelta =
          Number(asBool(right.available)) - Number(asBool(left.available));
        return availableDelta || left.name.localeCompare(right.name);
      });

    const canApply = !!(
      inspectedSpecies &&
      asBool(inspectedSpecies.available) &&
      inspectedSpecies.id !== data.species_id
    );

    const SpeciesFilterButton = (props: {
      id: 'all' | 'available' | 'locked';
      label: string;
      icon: string;
    }) => (
      <Button
        icon={props.icon}
        selected={speciesFilter === props.id}
        onClick={() => setSpeciesFilter(props.id)}
      >
        {props.label}
      </Button>
    );

    return (
      <Panel title="Choose Species" icon="users">
        <Stack>
          <Stack.Item basis="265px">
            <Input
              fluid
              placeholder="Search species..."
              value={speciesSearch}
              onChange={(value: string) => setSpeciesSearch(value)}
            />
            <Box mt={0.5} mb={0.75}>
              <SpeciesFilterButton id="all" label="All" icon="list" />
              <SpeciesFilterButton
                id="available"
                label="Open"
                icon="check-circle"
              />
              <SpeciesFilterButton id="locked" label="Locked" icon="lock" />
            </Box>
            <Box
              style={{
                maxHeight: '360px',
                overflowY: 'auto',
                paddingRight: '3px',
              }}
            >
              {filteredSpecies.length ? (
                filteredSpecies.map((species) => {
                  const selected = species.id === inspectedSpecies?.id;
                  const current = species.id === data.species_id;
                  const available = asBool(species.available);
                  return (
                    <Button
                      key={species.id}
                      fluid
                      mb={0.5}
                      selected={selected}
                      tooltip={species.name}
                      onClick={() => setPreviewSpeciesId(species.id)}
                      style={{
                        minHeight: '52px',
                        padding: '5px 6px',
                      }}
                    >
                      <Stack align="center">
                        <Stack.Item>
                          <Icon
                            name={
                              current
                                ? 'check-circle'
                                : available
                                  ? 'user'
                                  : 'lock'
                            }
                            color={
                              current
                                ? 'good'
                                : available
                                  ? undefined
                                  : 'average'
                            }
                          />
                        </Stack.Item>
                        <Stack.Item grow>
                          <Box textAlign="left" bold>
                            {species.name}
                          </Box>
                          <Box
                            textAlign="left"
                            color="label"
                            style={{
                              fontSize: '10px',
                              lineHeight: '12px',
                              overflow: 'hidden',
                              whiteSpace: 'normal',
                              maxHeight: '24px',
                            }}
                          >
                            {available
                              ? (species.tags || []).slice(0, 2).join(' / ') ||
                                species.language
                              : species.lock_reason || 'Unavailable'}
                          </Box>
                        </Stack.Item>
                      </Stack>
                    </Button>
                  );
                })
              ) : (
                <Box color="label" py={2} textAlign="center">
                  No species match.
                </Box>
              )}
            </Box>
          </Stack.Item>

          <Stack.Item grow basis={0}>
            {inspectedSpecies ? (
              <Section
                fill
                title={
                  <Stack align="center">
                    <Stack.Item>{inspectedSpecies.name}</Stack.Item>
                    {inspectedSpecies.id === data.species_id ? (
                      <Stack.Item>
                        <Box color="good">Current</Box>
                      </Stack.Item>
                    ) : null}
                  </Stack>
                }
                buttons={
                  !asBool(inspectedSpecies.available) ? (
                    <Button icon="lock" disabled>
                      {display(inspectedSpecies.lock_reason, 'Locked')}
                    </Button>
                  ) : null
                }
              >
                <Stack align="center" mb={1}>
                  <Stack.Item grow>
                    <Box color="label">
                      {inspectedSpecies.id === data.species_id
                        ? 'Selected species'
                        : asBool(inspectedSpecies.available)
                          ? 'Ready to apply'
                          : display(inspectedSpecies.lock_reason, 'Locked')}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon={
                        inspectedSpecies.id === data.species_id || canApply
                          ? 'check'
                          : 'lock'
                      }
                      color={canApply ? 'green' : undefined}
                      disabled={!canApply}
                      tooltip={
                        canApply
                          ? 'Apply species'
                          : inspectedSpecies.id === data.species_id
                            ? 'Current species'
                            : inspectedSpecies.lock_reason || 'Unavailable'
                      }
                      onClick={() =>
                        doPref('character_setup_select_species', undefined, {
                          species_id: inspectedSpecies.id,
                        })
                      }
                    >
                      {inspectedSpecies.id === data.species_id
                        ? 'Current Species'
                        : asBool(inspectedSpecies.available)
                          ? 'Apply Species'
                          : 'Locked'}
                    </Button>
                  </Stack.Item>
                </Stack>
                <Box
                  mb={1}
                  color={asBool(inspectedSpecies.available) ? undefined : 'label'}
                  style={{
                    minHeight: '118px',
                    maxHeight: '132px',
                    overflowY: 'auto',
                    whiteSpace: 'pre-line',
                  }}
                >
                  {display(inspectedSpecies.description, 'No description.')}
                </Box>

                <Stack mb={1}>
                  <Stack.Item grow>
                    <InfoRow
                      icon="language"
                      label="Language"
                      value={inspectedSpecies.language}
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <InfoRow
                      icon="leaf"
                      label="Ancestry"
                      value={inspectedSpecies.ancestry_label}
                    />
                  </Stack.Item>
                </Stack>
                <InfoRow
                  icon="hourglass-half"
                  label="Ages"
                  value={inspectedSpecies.ages}
                />

                {inspectedSpecies.stats?.length ? (
                  <FieldBlock label="Stat modifiers">
                    <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                      {inspectedSpecies.stats.map((stat) => (
                        <Button
                          key={stat.label}
                          compact
                          tooltip={stat.name}
                          color={stat.value > 0 ? 'green' : 'bad'}
                        >
                          {stat.label} {stat.value > 0 ? '+' : ''}
                          {stat.value}
                        </Button>
                      ))}
                    </Box>
                  </FieldBlock>
                ) : (
                  <FieldBlock label="Stat modifiers">
                    <Box color="label">No stat modifiers.</Box>
                  </FieldBlock>
                )}

                <FieldBlock label="Tags">
                  <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                    {(inspectedSpecies.tags || []).map((tag) => (
                      <Button
                        key={tag}
                        compact
                        color="transparent"
                        tooltip={inspectedSpecies.tag_descriptions?.[tag] || tag}
                        style={{
                          maxWidth: '100%',
                          whiteSpace: 'normal',
                          lineHeight: '14px',
                        }}
                      >
                        {tag}
                      </Button>
                    ))}
                  </Box>
                </FieldBlock>

                {!asBool(inspectedSpecies.available) ? (
                  <Box color="average">
                    <Icon name="lock" /> {display(inspectedSpecies.lock_reason)}
                  </Box>
                ) : null}
              </Section>
            ) : (
              <Section fill>
                <Box color="label">No species available.</Box>
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Panel>
    );
  };

  const renderFaithPicker = () => {
    const faithOptions = data.faith_options ?? [];
    const currentFaith = faithOptions.find((faith) => asBool(faith.selected));
    const inspectedFaith =
      faithOptions.find((faith) => faith.id === previewFaithId) ||
      currentFaith ||
      faithOptions[0];
    const selectedPatron =
      inspectedFaith?.patrons?.find((patron) => asBool(patron.selected)) ||
      inspectedFaith?.patrons?.[0];

    return (
      <Panel title="Choose Faith" icon="asterisk">
        <Stack wrap>
          <Stack.Item basis="220px" style={{ minWidth: 0 }}>
            <Box
              p={0.5}
              style={{
                maxHeight: '420px',
                overflowY: 'auto',
                border: '1px solid rgba(255,255,255,0.18)',
                backgroundColor: 'rgba(0,0,0,0.22)',
              }}
            >
              {faithOptions.length ? (
                faithOptions.map((faith) => (
                  <Button
                    key={faith.id}
                    fluid
                    mb={0.5}
                    selected={faith.id === inspectedFaith?.id}
                    disabled={!asBool(faith.available)}
                    tooltip={faith.name}
                    onClick={() => setPreviewFaithId(faith.id)}
                    style={{ minHeight: '46px', padding: '5px 6px' }}
                  >
                    <Stack align="center">
                      <Stack.Item>
                        <Icon
                          name={asBool(faith.selected) ? 'check-circle' : 'asterisk'}
                          color={asBool(faith.selected) ? 'good' : undefined}
                        />
                      </Stack.Item>
                      <Stack.Item grow>
                        <Box textAlign="left" bold>
                          {faith.name}
                        </Box>
                        <Box
                          textAlign="left"
                          color="label"
                          style={{ fontSize: '10px', lineHeight: '12px' }}
                        >
                          {(faith.patrons || []).length} patrons
                        </Box>
                      </Stack.Item>
                    </Stack>
                  </Button>
                ))
              ) : (
                <Box color="label" py={2} textAlign="center">
                  No faiths available.
                </Box>
              )}
            </Box>
          </Stack.Item>

          <Stack.Item grow basis="260px" style={{ minWidth: 0 }}>
            {inspectedFaith ? (
              <Section
                fill
                title={
                  <Stack align="center">
                    <Stack.Item>{inspectedFaith.name}</Stack.Item>
                    {asBool(inspectedFaith.selected) ? (
                      <Stack.Item>
                        <Box color="good">Current</Box>
                      </Stack.Item>
                    ) : null}
                  </Stack>
                }
                buttons={
                  asBool(inspectedFaith.available) &&
                  !asBool(inspectedFaith.selected) ? (
                    <Button
                      icon="check"
                      color="green"
                      tooltip="Choose this faith's godhead"
                      onClick={() =>
                        doPref('character_setup_select_faith', undefined, {
                          faith_id: inspectedFaith.id,
                        })
                      }
                    >
                      Use Faith
                    </Button>
                  ) : null
                }
              >
                <Box
                  mb={1}
                  style={{
                    maxHeight: '92px',
                    overflowY: 'auto',
                    whiteSpace: 'pre-line',
                  }}
                >
                  {display(inspectedFaith.description, 'No description.')}
                </Box>

                <FieldBlock label="Patrons">
                  <Box
                    p={0.5}
                    style={{
                      maxHeight: '300px',
                      overflowY: 'auto',
                      border: '1px solid rgba(255,255,255,0.18)',
                      backgroundColor: 'rgba(0,0,0,0.22)',
                    }}
                  >
                    {(inspectedFaith.patrons || []).map((patron) => (
                      <Button
                        key={patron.id}
                        fluid
                        mb={0.5}
                        selected={asBool(patron.selected)}
                        disabled={!asBool(patron.available)}
                        tooltip={patron.domain || patron.name}
                        onClick={() =>
                          doPref('character_setup_select_patron', undefined, {
                            patron_id: patron.id,
                          })
                        }
                        style={{ padding: '6px', minHeight: '58px' }}
                      >
                        <Stack align="center">
                          <Stack.Item>
                            <Icon
                              name={asBool(patron.selected) ? 'check-circle' : 'star'}
                              color={asBool(patron.selected) ? 'good' : undefined}
                            />
                          </Stack.Item>
                          <Stack.Item grow>
                            <Box textAlign="left" bold>
                              {patron.name}
                            </Box>
                            <Box textAlign="left" color="label">
                              {display(patron.domain)}
                            </Box>
                            <Box
                              textAlign="left"
                              style={{
                                fontSize: '11px',
                                lineHeight: '13px',
                                whiteSpace: 'normal',
                                display: '-webkit-box',
                                WebkitLineClamp: 2,
                                WebkitBoxOrient: 'vertical',
                                overflow: 'hidden',
                              }}
                            >
                              {display(patron.description, 'No description.')}
                            </Box>
                          </Stack.Item>
                        </Stack>
                      </Button>
                    ))}
                  </Box>
                </FieldBlock>

                {selectedPatron ? (
                  <>
                    <InfoRow icon="star" label="Patron" value={selectedPatron.name} />
                    <InfoRow icon="sun" label="Domain" value={selectedPatron.domain} />
                    <FieldBlock label="About">
                      <Box style={{ whiteSpace: 'pre-line' }}>
                        {display(selectedPatron.description, 'No description.')}
                      </Box>
                    </FieldBlock>
                    <FieldBlock label="Boons">
                      <Box>{display(selectedPatron.boons)}</Box>
                    </FieldBlock>
                    <FieldBlock label="Sins">
                      <Box color="bad">{display(selectedPatron.sins)}</Box>
                    </FieldBlock>
                  </>
                ) : null}
              </Section>
            ) : (
              <Section fill>
                <Box color="label">No faiths available.</Box>
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Panel>
    );
  };

  const renderAncestryPicker = () => {
    const ancestryOptions = data.ancestry_options ?? [];
    const title = `Choose ${display(data.ancestry_label, 'Ancestry')}`;

    return (
      <Panel title={title} icon="leaf">
        <Section
          title={
            <Stack align="center">
              <Stack.Item>{display(data.ancestry_label, 'Ancestry')}</Stack.Item>
              <Stack.Item>
                <Box color="good">{display(data.ancestry_value)}</Box>
              </Stack.Item>
            </Stack>
          }
        >
          <Box style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
            {ancestryOptions.length ? (
              ancestryOptions.map((option) => (
                <Button
                  key={option.value}
                  selected={asBool(option.selected)}
                  tooltip={option.name}
                  onClick={() =>
                    doPref('character_setup_select_ancestry', undefined, {
                      ancestry: option.value,
                    })
                  }
                  style={{ minWidth: '126px', padding: '6px' }}
                >
                  <Stack align="center">
                    <Stack.Item>
                      <Box
                        width="28px"
                        height="16px"
                        style={{ border: '1px solid rgba(0,0,0,0.65)' }}
                        backgroundColor={swatchColor(option.color)}
                      />
                    </Stack.Item>
                    <Stack.Item grow>
                      <Box textAlign="left" bold>
                        {option.name}
                      </Box>
                    </Stack.Item>
                  </Stack>
                </Button>
              ))
            ) : (
              <Box color="label">No ancestry choices available.</Box>
            )}
          </Box>
        </Section>
      </Panel>
    );
  };

  const renderSelectionPanel = () => {
    if (selectionMode === 'faith') {
      return renderFaithPicker();
    }
    if (selectionMode === 'ancestry') {
      return renderAncestryPicker();
    }
    return renderSpeciesPicker();
  };

  const renderIdentity = () => (
    <>
      <Stack>
        <Stack.Item grow basis={0}>
          <Panel title="Identity" icon="id-card">
            <PrefRow icon="signature" label="Name" value={data.real_name} onClick={() => doPref('name', 'input')} />
            <PrefRow icon="venus-mars" label="Body Type" value={data.gender} onClick={() => doPref('gender')} />
            <PrefRow icon="comment" label="Pronouns" value={data.pronouns} onClick={() => doPref('pronouns', 'input')} />
            <FieldBlock label="Age">
              <Tooltip
                content={data.age_tooltips?.[data.age] ?? ''}
                position="bottom"
              >
                <Box>
                  <Dropdown
                    width="100%"
                    displayText={display(data.age)}
                    selected={display(data.age)}
                    options={ageOptions.map((option, index) => ({
                      displayText: display(option, option),
                      value: index + 1,
                    }))}
                    onSelected={(value) => act('set_age', { value })}
                  />
                </Box>
              </Tooltip>
            </FieldBlock>
            <SelectionModeButtons />
          </Panel>
        </Stack.Item>

        <Stack.Item grow basis={0} ml={1}>
          <Panel title="Standing" icon="sun">
            <PrefRow icon="hand-paper" label="Dominant Hand" value={data.domhand} onClick={() => doPref('domhand')} />
            <PrefRow icon="theater-masks" label="Quirks" value="Select" onClick={() => doPref('select_quirks')} />
          </Panel>
        </Stack.Item>
      </Stack>

      {renderSelectionPanel()}
    </>
  );

  const renderColorSwatches = (feature: FeatureEntry) => (
    <Box style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center' }}>
      {(feature.colors || []).map((color) => (
        <Button
          key={color.index}
          mr={0.5}
          tooltip={color.name}
          onClick={() =>
            customizerAct(feature.key, 'acc_color', { color_index: color.index })
          }
        >
          <Box
            inline
            width="22px"
            height="11px"
            verticalAlign="middle"
            backgroundColor={swatchColor(color.value)}
          />
        </Button>
      ))}
      <Button
        icon="undo"
        tooltip="Reset colors"
        onClick={() => customizerAct(feature.key, 'reset_colors')}
      />
    </Box>
  );

  const renderFeatureExtras = (feature: FeatureEntry) => {
    const extras = feature.extras || [];
    if (!extras.length) {
      return null;
    }

    return (
      <Box
        style={{
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          gap: '4px 6px',
        }}
      >
        {extras.map((extra) => (
          <Box
            key={extra.task}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <Box color="label" style={{ fontSize: '12px', lineHeight: '14px' }}>
              {extra.label}
            </Box>
            <Button
              compact
              tooltip={extra.label}
              onClick={() => customizerAct(feature.key, extra.task)}
            >
              {extra.kind === 'color' ? (
                <Box
                  inline
                  width="22px"
                  height="11px"
                  verticalAlign="middle"
                  backgroundColor={swatchColor(extra.value)}
                />
              ) : (
                display(extra.value)
              )}
            </Button>
          </Box>
        ))}
      </Box>
    );
  };

  const renderFeatureBody = (feature: FeatureEntry, skipColors?: boolean) => {
    const extraControls = renderFeatureExtras(feature);

    return (
      <>
        {!skipColors && feature.colors?.length ? (
          <FieldBlock label="Colors">{renderColorSwatches(feature)}</FieldBlock>
        ) : null}

        {feature.choice_options ? (
          <FieldBlock label="Type">
            <OptionGrid
              options={feature.choice_options}
              selected={feature.choice_value}
              onSelect={(value) =>
                doPref('character_setup_set_choice', undefined, {
                  key: feature.key,
                  choice_type: value,
                })
              }
            />
          </FieldBlock>
        ) : null}

        {feature.accessory_options ? (
          <Box mb={1}>
            <Stack align="center" mb={0.5}>
              <Stack.Item>
                <Box color="label">Style</Box>
              </Stack.Item>
              {extraControls ? <Stack.Item grow>{extraControls}</Stack.Item> : null}
            </Stack>
            <OptionGrid
              options={feature.accessory_options}
              selected={feature.accessory_value}
              onSelect={(value) =>
                customizerAct(feature.key, 'select_acc', { acc_type: value })
              }
              onHover={(v) =>
                requestHover(
                  v,
                  feature.colors?.[0]?.value ??
                    feature.extras?.find((e) => e.kind === 'color')?.value,
                  feature.key,
                )
              }
              thumbs={data.thumbs}
            />
          </Box>
        ) : feature.accessory_name ? (
          <Box mb={1}>
            <Stack align="center" mb={0.5}>
              <Stack.Item>
                <Box color="label">Style</Box>
              </Stack.Item>
              {extraControls ? <Stack.Item grow>{extraControls}</Stack.Item> : null}
            </Stack>
            <Box>{feature.accessory_name}</Box>
          </Box>
        ) : extraControls ? (
          <FieldBlock label="Options">{extraControls}</FieldBlock>
        ) : null}
      </>
    );
  };
  const renderFeatureEditor = (feature: FeatureEntry, showName?: boolean) => {
    const enabled = asBool(feature.enabled);
    return (
      <Box mb={1}>
        {showName || asBool(feature.can_disable) ? (
          <Stack align="center" mb={0.5}>
            {showName ? (
              <Stack.Item>
                <Box bold>{feature.name}</Box>
              </Stack.Item>
            ) : null}
            {asBool(feature.can_disable) ? (
              <Stack.Item>
                <Button
                  icon={enabled ? 'toggle-on' : 'toggle-off'}
                  selected={enabled}
                  onClick={() => customizerAct(feature.key, 'toggle_missing')}
                >
                  {enabled ? 'On' : 'Off'}
                </Button>
              </Stack.Item>
            ) : null}
          </Stack>
        ) : null}
        {enabled ? (
          renderFeatureBody(feature)
        ) : (
          <Box color="label">This feature is hidden.</Box>
        )}
      </Box>
    );
  };

  const renderTaurEditor = () => (
    <>
      <PrefRow icon="paw" label="Body" value={data.taur_body} onClick={() => doPref('character_setup_taur_body')} />
      <PrefRow icon="palette" label="Color" swatch={data.taur_color} value={data.taur_color} onClick={() => doPref('character_setup_taur_color', undefined, { which: 'base' })} />
      <PrefRow icon="palette" label="Markings" swatch={data.taur_markings} value={data.taur_markings} onClick={() => doPref('character_setup_taur_color', undefined, { which: 'markings' })} />
      <PrefRow icon="palette" label="Tertiary" swatch={data.taur_tertiary} value={data.taur_tertiary} onClick={() => doPref('character_setup_taur_color', undefined, { which: 'tertiary' })} />
    </>
  );

  const renderBackdropEditor = () => (
    <FieldBlock label="Backdrop tile" labelSize="18px">
      <OptionGrid
        options={data.background_options ?? []}
        selected={data.background}
        labelSize="15px"
        onSelect={(value) =>
          doPref('character_setup_preview_background', undefined, { bg: value })
        }
      />
    </FieldBlock>
  );

  const renderFeatureCard = (feature: FeatureEntry) => {
    const enabled = asBool(feature.enabled);
    return (
      <Section
        key={feature.key}
        mb={1}
        title={feature.name}
        buttons={
          asBool(feature.can_disable) ? (
            <Button
              icon={enabled ? 'toggle-on' : 'toggle-off'}
              selected={enabled}
              onClick={() => customizerAct(feature.key, 'toggle_missing')}
            >
              {enabled ? 'On' : 'Off'}
            </Button>
          ) : null
        }
      >
        {enabled ? renderFeatureBody(feature) : null}
      </Section>
    );
  };

  const renderUnderwearEditor = () => {
    const catalog = data.smallclothes_catalog ?? [];
    const state = data.smallclothes ?? { random: false, entries: [] };
    const isRandom = asBool(state.random);
    const entryOf = (id: string) =>
      (state.entries ?? []).find((entry) => entry.id === id);
    return (
      <>
        <Stack align="center" mb={1}>
          <Stack.Item grow>
            <Box color="label">
              Item-based smallclothes, worn on spawn and shown on the doll.
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon={isRandom ? 'dice' : 'hand-pointer'}
              selected={isRandom}
              onClick={() => doPref('character_setup_smallclothes_random')}
            >
              {isRandom ? 'Randomized' : 'Manual'}
            </Button>
          </Stack.Item>
        </Stack>
        {isRandom ? (
          <Box color="label">
            Smallclothes are randomized every round. Switch to Manual to pick.
          </Box>
        ) : (
          catalog.map((category) => {
            const entry = entryOf(category.id);
            return (
              <FieldBlock
                key={category.id}
                label={`${category.name} — ${entry?.name || 'None'}`}
              >
                <Stack align="center" mb={0.5}>
                  <Stack.Item>
                    <Button
                      icon="palette"
                      onClick={() =>
                        doPref('character_setup_smallclothes_color', undefined, {
                          category: category.id,
                        })
                      }
                    >
                      Color
                    </Button>
                  </Stack.Item>
                  {entry?.color ? (
                    <Stack.Item>
                      <Box
                        style={{
                          display: 'inline-block',
                          width: '14px',
                          height: '14px',
                          verticalAlign: 'middle',
                          borderRadius: '3px',
                          border: '1px solid rgba(255,255,255,0.35)',
                          backgroundColor: swatchColor(entry.color),
                        }}
                      />
                    </Stack.Item>
                  ) : null}
                </Stack>
                <OptionGrid
                  options={category.options}
                  selected={entry?.value || ''}
                  onSelect={(value) =>
                    doPref('character_setup_smallclothes_set', undefined, {
                      category: category.id,
                      value,
                    })
                  }
                />
              </FieldBlock>
            );
          })
        )}
      </>
    );
  };

  const renderBodyEditor = () => (
    <>
      <ActionButton icon="paint-brush" label="Body Markings" onClick={() => doPref('markings', 'menu')} />
      {(data.mutant_colors ?? []).map((entry) => (
        <PrefRow
          key={entry.slot}
          icon="palette"
          label={`Mutant Color #${entry.slot}`}
          swatch={entry.color}
          value={entry.color}
          onClick={() =>
            doPref('character_setup_mutant_color', undefined, {
              slot: entry.slot,
            })
          }
        />
      ))}
      {asBool(data.use_skintones) ? (
        <ActionButton icon="list" label="Skin Color Reference" onClick={() => doPref('skin_color_ref_list', 'input')} />
      ) : null}
      {asBool(data.use_titles) ? (
        <PrefRow icon="crown" label="Race Title" value={data.race_title} onClick={() => doPref('race_title', 'input')} />
      ) : null}
    </>
  );

  const renderGenitalsEditor = (erpFeatures: FeatureEntry[]) => (
    <>
      <Stack align="center" mb={1}>
        <Stack.Item grow>
          <Box>
            <Box as="span" color="label">
              Genital Set:{' '}
            </Box>
            <Box as="span" bold>
              {display(data.genital_set_label)}
            </Box>
          </Box>
          {asBool(data.genital_extra_unlock) ? (
            <Box color="label" fontSize="11px">
              Extra Genitals lets you mix and match genital features.
            </Box>
          ) : null}
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="exchange-alt"
            onClick={() => doPref('character_setup_toggle_genital_set')}
          >
            Toggle Genitals
          </Button>
        </Stack.Item>
      </Stack>
      {erpFeatures.length ? (
        erpFeatures.map(renderFeatureCard)
      ) : (
        <Box color="label">
          No intimate customization available for this species.
        </Box>
      )}
    </>
  );

  const renderAppearance = () => {
    const allFeatures = data.features || [];
    const erpFeatures = allFeatures.filter((feature) => asBool(feature.erp));
    const appearanceFeatures = allFeatures.filter(
      (feature) => !asBool(feature.erp),
    );
    const faceFeatures = appearanceFeatures.filter((feature) =>
      isFaceFeature(feature.key),
    );
    const otherFeatures = appearanceFeatures.filter(
      (feature) => !isFaceFeature(feature.key),
    );

    const featureTabs = [
      { key: UNDERWEAR_KEY, name: 'Underwear' },
      { key: BODY_KEY, name: 'Body' },
      ...(faceFeatures.length ? [{ key: FACE_KEY, name: 'Face Details' }] : []),
      ...otherFeatures.map((feature) => ({
        key: feature.key,
        name: feature.name,
      })),
      ...(asBool(data.is_taur) ? [{ key: TAUR_KEY, name: 'Taur Body' }] : []),
      { key: GENITALS_KEY, name: 'Genitals' },
      { key: BACKDROP_KEY, name: 'Backdrop' },
    ];
    const currentKey = featureTabs.some((tab) => tab.key === activeFeature)
      ? activeFeature
      : featureTabs[0]?.key;

    const renderEditor = () => {
      if (currentKey === UNDERWEAR_KEY) {
        return renderUnderwearEditor();
      }
      if (currentKey === BODY_KEY) {
        return renderBodyEditor();
      }
      if (currentKey === GENITALS_KEY) {
        return renderGenitalsEditor(erpFeatures);
      }
      if (currentKey === BACKDROP_KEY) {
        return renderBackdropEditor();
      }
      if (currentKey === TAUR_KEY) {
        return renderTaurEditor();
      }
      if (currentKey === FACE_KEY) {
        if (!faceFeatures.length) {
          return <Box color="label">No face details for this species.</Box>;
        }
        return faceFeatures.map((feature) => (
          <Fragment key={feature.key}>
            {renderFeatureEditor(feature, true)}
          </Fragment>
        ));
      }
      const feature = otherFeatures.find((entry) => entry.key === currentKey);
      if (!feature) {
        return (
          <Box color="label">No customization available for this species.</Box>
        );
      }
      return renderFeatureEditor(feature, false);
    };

    return (
      <Panel title="Appearance" icon="palette">
        <Box style={{ display: 'flex', flexWrap: 'wrap' }} mb={1}>
          {featureTabs.map((tab) => (
            <Button
              key={tab.key}
              mr={0.5}
              mb={0.5}
              selected={tab.key === currentKey}
              onClick={() => setActiveFeature(tab.key)}
            >
              {tab.name}
            </Button>
          ))}
        </Box>
        <Section>{renderEditor()}</Section>
      </Panel>
    );
  };

  const renderVoice = () => (
    <Panel title="Voice" icon="volume-up">
      <PrefRow icon="microphone" label="Voice Type" value={data.voice_type} onClick={() => doPref('voicetype', 'input')} />
      <PrefRow icon="comment-dots" label="Accent" value={data.selected_accent} onClick={() => doPref('selected_accent', 'input')} />
      <PrefRow icon="tint" label="Voice Color" swatch={data.voice_color} value={data.voice_color} onClick={() => doPref('voice', 'input')} />
      <PrefRow icon="volume-up" label="Voice Pack" value={data.voice_pack} onClick={() => doPref('voicepack', 'input')} />
      <PrefRow icon="play" label="Pack Preview" value="Play" onClick={() => doPref('voicepreview', 'input')} />
      <PrefRow icon="kiss-wink-heart" label="Moans" value={data.moan_selection} onClick={() => doPref('moanselection', 'input')} />
      <PrefRow icon="play" label="Moan Preview" value="Play" onClick={() => doPref('moanpreview', 'input')} />
    </Panel>
  );

  const renderBackground = () => (
    <>
      <Panel title="Flavour" icon="scroll">
        <PrefRow icon="align-left" label="Flavour Text" value="Edit" onClick={() => doPref('flavortext', 'input')} />
        <PrefRow icon="align-left" label="NSFW Flavour Text" value="Edit" onClick={() => doPref('nsfwflavortext', 'input')} />
        <PrefRow icon="tags" label="Descriptors" value="Edit" onClick={() => doPref('descriptors', 'menu')} />
        <PrefRow icon="map" label="Culture" value={data.culture_name} onClick={() => doPref('culture', 'input')} />
        <PrefRow icon="utensils" label="Food Preferences" value="Edit" onClick={() => doPref('culinary', 'menu')} />
      </Panel>

      <Panel title="OOC" icon="sticky-note">
        <PrefRow icon="sticky-note" label="OOC Notes" value="Edit" onClick={() => doPref('ooc_notes', 'input')} />
        <PrefRow icon="paperclip" label="OOC Extra" value="Edit" onClick={() => doPref('ooc_extra', 'input')} />
        <PrefRow icon="eye" label="Preview OOC Card" value="View" onClick={() => doPref('ooc_preview', 'input')} />
      </Panel>
    </>
  );

  const renderGameplay = () => (
    <>
      <Panel title="Class & Roles" icon="shield-alt">
        <PrefRow icon="briefcase" label="Class / Jobs" value={data.high_job} onClick={() => doPref('job', 'menu')} />
        <PrefRow icon="list-ol" label="Ready Order" value="Edit" onClick={() => doPref('multi', 'menu')} />
      </Panel>

      <Panel title="Loadout" icon="shopping-bag">
        <ActionButton icon="box" label="Open Loadout Menu" onClick={() => doPref('loadout_item', 'input')} />
      </Panel>

      <Panel title="Combat & Defeat" icon="skull">
        <PrefRow icon="music" label="Combat Music" value={data.combat_music} onClick={() => doPref('combat_music', 'input')} />
        <PrefRow icon="skull" label="Defeat Mode" value={data.defeat_mode} onClick={() => doPref('defeat_mode', 'input')} />
        <PrefRow icon="heart-broken" label="Defeat Threshold" value={data.defeat_threshold} onClick={() => doPref('defeat_threshold', 'input')} />
      </Panel>

      {/* Triumphs are disabled for now.
      <Panel title="Triumphs" icon="trophy">
        <InfoRow icon="coins" label="Balance" value={data.triumphs} />
        <ActionButton icon="list" label="Triumph List" onClick={() => doPref('triumphs')} />
        <ActionButton icon="shopping-bag" label="Triumph Shop" onClick={() => doPref('triumph_buy_menu')} />
      </Panel>
      */}
    </>
  );

  const renderHeadshotPreview = (src: string | null, label: string) => (
    <Stack.Item grow basis={0}>
      <Box color="label" mb={0.5} textAlign="center">
        {label}
      </Box>
      <Box textAlign="center">
        {src ? (
          <img
            src={src}
            alt=""
            style={{ maxWidth: '100%', maxHeight: '260px' }}
          />
        ) : (
          <Box py={3} color="label">
            <Icon name="user" size={4} />
            <Box mt={1}>Not set</Box>
          </Box>
        )}
      </Box>
    </Stack.Item>
  );

  const renderProfile = () => (
    <>
      <Panel title="Profile Link" icon="image">
        <Stack mb={1}>
          {renderHeadshotPreview(data.headshot, 'Headshot')}
          {renderHeadshotPreview(data.nsfw_headshot, 'NSFW Headshot')}
        </Stack>
        <ActionButton icon="link" label="Set Headshot URL" onClick={() => doPref('headshot', 'input')} />
        <ActionButton icon="link" label="Set NSFW Headshot URL" onClick={() => doPref('nsfw_headshot', 'input')} />
        <ActionButton icon="images" label="Gallery" onClick={() => doPref('gallery', 'menu', { tab: 'regular' })} />
        <ActionButton icon="images" label="NSFW Gallery" onClick={() => doPref('gallery', 'menu', { tab: 'nsfw' })} />
      </Panel>

      <Panel title="Rumours & Song" icon="feather">
        <PrefRow icon="comment-dots" label="Rumours" value="Edit" onClick={() => doPref('rumour', 'input')} />
        <PrefRow icon="crown" label="Noble Gossip" value="Edit" onClick={() => doPref('gossip', 'input')} />
        <PrefRow icon="eye" label="Preview Rumours" value="View" onClick={() => doPref('rumour_preview', 'input')} />
        <PrefRow icon="music" label="Examine Song URL" value={asBool(data.song_set) ? 'URL set' : 'No URL set'} onClick={() => doPref('song_link', 'input')} />
        <PrefRow icon="heading" label="Song Title" value={data.song_title} onClick={() => doPref('change_title', 'input')} />
        <PrefRow icon="user" label="Song Artist" value={data.song_artist} onClick={() => doPref('change_artist', 'input')} />
      </Panel>
    </>
  );

  const erpGeneralAct = (
    prefType: string,
    action: string,
    extra?: Record<string, unknown>,
  ) => {
    act('pref', {
      preference: 'erp_pref_native',
      task: 'erp_pref',
      native: 1,
      pref_type: prefType,
      action,
      ...(extra || {}),
    });
  };

  const erpKinkAct = (
    kinkName: string,
    action: string,
    extra?: Record<string, unknown>,
  ) => {
    act('pref', {
      preference: 'kink',
      task: 'erp_pref',
      native: 1,
      kink_name: kinkName,
      action,
      ...(extra || {}),
    });
  };

  const renderErpPrefControl = (pref: ErpPrefEntry, locked: boolean) => {
    if (pref.kind === 'flags') {
      return (
        <Box style={{ display: 'flex', flexWrap: 'wrap' }}>
          {(pref.flags ?? []).map((flag) => (
            <Button
              key={flag.bit}
              mr={0.5}
              mb={0.5}
              compact
              disabled={locked}
              selected={asBool(flag.on)}
              tooltip={flag.description || flag.name}
              onClick={() =>
                erpGeneralAct(pref.type, 'toggle_flag', { flag: flag.bit })
              }
            >
              {flag.name}
            </Button>
          ))}
        </Box>
      );
    }
    if (pref.kind === 'number') {
      return (
        <Stack align="center">
          <Stack.Item>
            <Button
              compact
              icon="chevron-left"
              disabled={locked}
              onClick={() => erpGeneralAct(pref.type, 'decrease')}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              compact
              disabled={locked}
              tooltip={`${pref.min} - ${pref.max}`}
              onClick={() => erpGeneralAct(pref.type, 'set')}
            >
              {display(pref.value, '0')}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              compact
              icon="chevron-right"
              disabled={locked}
              onClick={() => erpGeneralAct(pref.type, 'increase')}
            />
          </Stack.Item>
        </Stack>
      );
    }
    if (pref.kind === 'choice') {
      return (
        <Stack align="center">
          <Stack.Item>
            <Button
              compact
              icon="chevron-left"
              disabled={locked}
              onClick={() => erpGeneralAct(pref.type, 'prev')}
            />
          </Stack.Item>
          <Stack.Item>
            <Button
              compact
              disabled={locked}
              onClick={() => erpGeneralAct(pref.type, 'choose')}
            >
              {display(pref.value)}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              compact
              icon="chevron-right"
              disabled={locked}
              onClick={() => erpGeneralAct(pref.type, 'next')}
            />
          </Stack.Item>
        </Stack>
      );
    }
    return (
      <Button
        compact
        disabled={locked}
        selected={asBool(pref.value as Booleanish)}
        color={asBool(pref.value as Booleanish) ? 'good' : 'bad'}
        onClick={() => erpGeneralAct(pref.type, 'toggle')}
      >
        {asBool(pref.value as Booleanish) ? 'Enabled' : 'Disabled'}
      </Button>
    );
  };

  const renderErpKink = (kink: ErpKink, locked: boolean) => {
    const enabled = asBool(kink.enabled);
    return (
      <Stack key={kink.name} align="baseline" mb={0.75}>
        <Stack.Item grow basis={0}>
          <Box bold>{kink.name}</Box>
          <Box color="label" fontSize="11px">
            {kink.description}
          </Box>
        </Stack.Item>
        <Stack.Item basis="55%">
          <Stack align="center" wrap>
            <Stack.Item>
              <Button
                compact
                disabled={locked}
                selected={enabled}
                color={enabled ? 'good' : 'bad'}
                onClick={() => erpKinkAct(kink.name, 'toggle_enabled')}
              >
                {enabled ? 'Yes' : 'No'}
              </Button>
            </Stack.Item>
            {enabled ? (
              <>
                {[1, 2, 3, 4, 5].map((level) => (
                  <Stack.Item key={level}>
                    <Button
                      compact
                      disabled={locked}
                      selected={kink.intensity === level}
                      onClick={() =>
                        erpKinkAct(kink.name, 'set_intensity', {
                          intensity: level,
                        })
                      }
                    >
                      {level}
                    </Button>
                  </Stack.Item>
                ))}
                <Stack.Item>
                  <Button
                    compact
                    icon="pen"
                    disabled={locked}
                    tooltip={kink.notes || 'No notes'}
                    onClick={() => erpKinkAct(kink.name, 'set_notes')}
                  >
                    Notes
                  </Button>
                </Stack.Item>
              </>
            ) : null}
          </Stack>
        </Stack.Item>
      </Stack>
    );
  };

  const [erpTab, setErpTab] = useState<'general' | 'kinks'>('general');

  const renderErp = () => {
    const erp = data.erp ?? {
      lock_reason: null,
      categories: [],
      kink_categories: [],
    };
    const locked = !!erp.lock_reason;
    return (
      <>
        {erp.lock_reason ? (
          <Section mb={1}>
            <Box color="bad">{erp.lock_reason}</Box>
          </Section>
        ) : null}
        <Tabs>
          <Tabs.Tab
            selected={erpTab === 'general'}
            onClick={() => setErpTab('general')}
          >
            General ERP
          </Tabs.Tab>
          <Tabs.Tab
            selected={erpTab === 'kinks'}
            onClick={() => setErpTab('kinks')}
          >
            Kinks
          </Tabs.Tab>
        </Tabs>
        {erpTab === 'general'
          ? (erp.categories ?? []).map((category) => (
              <Panel key={category.name} title={category.name} icon="sliders-h">
                {(category.prefs ?? []).map((pref) => (
                  <Stack key={pref.type} align="baseline" mb={0.75}>
                    <Stack.Item grow basis={0}>
                      <Box bold>{pref.name}</Box>
                      <Box color="label" fontSize="11px">
                        {pref.description}
                      </Box>
                    </Stack.Item>
                    <Stack.Item basis="45%">
                      {renderErpPrefControl(pref, locked)}
                    </Stack.Item>
                  </Stack>
                ))}
              </Panel>
            ))
          : (erp.kink_categories ?? []).map((category) => (
              <Panel key={category.name} title={category.name} icon="heart">
                {/* Kinks are editable at any time, matching the old window. */}
                {(category.kinks ?? []).map((kink) => renderErpKink(kink, false))}
              </Panel>
            ))}
      </>
    );
  };

  const renderSettings = () => {
    const game = data.game_prefs || ({} as PrefsData['game_prefs']);
    const toggle = (preference: string) => doPref(preference);

    return (
      <>
        <Panel title="Interface" icon="desktop">
          <PrefRow icon="keyboard" label="Hotkeys" value={asBool(game.hotkeys) ? 'ON' : 'OFF'} selected={asBool(game.hotkeys)} onClick={() => toggle('hotkeys')} />
          <PrefRow icon="mouse-pointer" label="Action Buttons" value={asBool(game.buttons_locked) ? 'Locked' : 'Unlocked'} selected={asBool(game.buttons_locked)} onClick={() => toggle('action_buttons')} />
          <PrefRow icon="window-restore" label="Fancy tgui" value={asBool(game.tgui_fancy) ? 'ON' : 'OFF'} selected={asBool(game.tgui_fancy)} onClick={() => toggle('tgui_fancy')} />
          <PrefRow icon="lock" label="Lock tgui Layout" value={asBool(game.tgui_lock) ? 'ON' : 'OFF'} selected={asBool(game.tgui_lock)} onClick={() => toggle('tgui_lock')} />
          <PrefRow icon="bolt" label="Window Flashing" value={asBool(game.windowflashing) ? 'ON' : 'OFF'} selected={asBool(game.windowflashing)} onClick={() => toggle('winflash')} />
        </Panel>

        <Panel title="Display" icon="eye">
          <PrefRow icon="comments" label="See Non-mob Chat" value={asBool(game.see_chat_non_mob) ? 'ON' : 'OFF'} selected={asBool(game.see_chat_non_mob)} onClick={() => toggle('see_chat_non_mob')} />
          <PrefRow icon="sun" label="Ambient Occlusion" value={asBool(game.ambientocclusion) ? 'ON' : 'OFF'} selected={asBool(game.ambientocclusion)} onClick={() => toggle('ambientocclusion')} />
          <PrefRow icon="expand" label="Auto-fit Viewport" value={asBool(game.auto_fit_viewport) ? 'ON' : 'OFF'} selected={asBool(game.auto_fit_viewport)} onClick={() => toggle('auto_fit_viewport')} />
          <PrefRow icon="tv" label="Widescreen" value={asBool(game.widescreenpref) ? 'ON' : 'OFF'} selected={asBool(game.widescreenpref)} onClick={() => toggle('widescreenpref')} />
          <PrefRow icon="search-plus" label="Pixel Size" value={game.pixel_size} onClick={() => toggle('pixel_size')} />
          <PrefRow icon="image" label="Scaling Method" value={game.scaling_method} onClick={() => toggle('scaling_method')} />
        </Panel>

        <Panel title="Audio & Round" icon="volume-up">
          <PrefRow icon="music" label="Lobby Music" value={asBool(game.lobby_music) ? 'ON' : 'OFF'} selected={asBool(game.lobby_music)} onClick={() => toggle('lobby_music')} />
          <PrefRow icon="music" label="Admin MIDIs" value={asBool(game.hear_midis) ? 'ON' : 'OFF'} selected={asBool(game.hear_midis)} onClick={() => toggle('hear_midis')} />
          <PrefRow icon="user-secret" label="Midround Antag" value={asBool(game.allow_midround_antag) ? 'ON' : 'OFF'} selected={asBool(game.allow_midround_antag)} onClick={() => toggle('allow_midround_antag')} />
        </Panel>

        <Panel title="Tools" icon="sliders-h">
          <PrefRow icon="globe" label="Player's Language" value="Set" onClick={() => doPref('player_language', 'input')} />
          <ActionButton icon="toggle-on" label="Toggle Bitfields" onClick={() => doPref('toggles')} />
          <ActionButton icon="keyboard" label="Keybinds" onClick={() => doPref('keybinds', 'menu')} />
          <ActionButton icon="save" label="Save Preferences" onClick={() => doPref('save')} />
        </Panel>
      </>
    );
  };

  const renderActiveSection = () => {
    switch (activeSection) {
      case 'appearance':
        return renderAppearance();
      case 'gameplay':
        return renderGameplay();
      case 'profile':
        return (
          <>
            {renderVoice()}
            {renderBackground()}
            {renderProfile()}
          </>
        );
      case 'erp':
        return renderErp();
      case 'settings':
        return renderSettings();
      default:
        return renderIdentity();
    }
  };

  const NavTab = (section: { id: string; label: string; icon: string }) => (
    <Tabs.Tab
      key={section.id}
      icon={section.icon}
      selected={activeSection === section.id}
      onClick={() => setActiveSection(section.id)}
    >
      {section.label}
    </Tabs.Tab>
  );

  const FooterSummary = (props: {
    icon: string;
    label: string;
    value?: unknown;
    onClick: () => void;
  }) => (
    <Button color="transparent" onClick={props.onClick} tooltip={props.label}>
      <Stack align="center">
        <Stack.Item>
          <Icon name={props.icon} />
        </Stack.Item>
        <Stack.Item>
          <Box color="label" fontSize="10px">
            {props.label}
          </Box>
          <Box bold>{display(props.value)}</Box>
        </Stack.Item>
      </Stack>
    </Button>
  );

  const RoundStartReport = () => (
    <Section title="Round Start" mb={1}>
      <Box bold fontSize="22px" color={roundStatusColor}>
        {roundCountdown}
      </Box>
      <Box color="label" mb={0.5}>
        {roundStatus}
      </Box>
      <Button
        fluid
        mb={0.75}
        icon={data.round_action_icon || 'user-check'}
        color={data.round_action_color || undefined}
        disabled={asBool(data.round_action_disabled)}
        tooltip={data.round_action_tooltip || data.round_action_label}
        onClick={() => doPref('character_setup_round_action')}
      >
        {display(data.round_action_label)}
      </Button>
      <Stack align="center">
        <Stack.Item>
          <Icon name="user-check" />
        </Stack.Item>
        <Stack.Item grow>
          <Box color="label">Ready</Box>
        </Stack.Item>
        <Stack.Item>
          <Box bold>
            {display(data.round_ready_players, '0')} /{' '}
            {display(data.round_total_players, '0')}
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );

  const WindowControls = () => (
    <Stack align="center">
      <Stack.Item>
        <Button
          compact
          icon="search-minus"
          tooltip="Smaller elements"
          disabled={menuScale <= 0.8}
          onClick={() => setMenuScale(menuScale - 0.05)}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          compact
          tooltip="Reset element scale"
          onClick={() => setMenuScale(0.85)}
        >
          {Math.round(menuScale * 100)}%
        </Button>
      </Stack.Item>
      <Stack.Item>
        <Button
          compact
          icon="search-plus"
          tooltip="Larger elements"
          disabled={menuScale >= 1.25}
          onClick={() => setMenuScale(menuScale + 0.05)}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          compact
          icon={isFullscreen ? 'compress' : 'expand'}
          tooltip={isFullscreen ? 'Collapse window' : 'Expand window'}
          onClick={() => doPref('character_setup_preferences_fullscreen')}
        />
      </Stack.Item>
    </Stack>
  );

  return (
    <Window
      title="Character Setup"
      width={windowWidth}
      height={windowHeight}
      theme="vanderlin"
      buttons={<WindowControls />}
    >
      <Window.Content>
        <Box height="100%" style={scaledContentStyle}>
          <Stack vertical fill>
            <Stack.Item>
              <Section>
                <Stack align="center">
                  <Stack.Item grow>
                    <Box bold fontSize="18px">
                      {display(data.real_name, 'Unnamed')}
                    </Box>
                    <Box color="label">{headerMeta}</Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button icon="exchange-alt" onClick={() => doPref('changeslot')}>
                      Change Character
                    </Button>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>

            <Stack.Item grow>
              <Stack fill>
                <Stack.Item basis="210px">
                  <Stack vertical fill>
                    <Stack.Item>
                      <RoundStartReport />
                    </Stack.Item>
                    <Stack.Item grow>
                      <Section fill scrollable>
                        <Tabs vertical>
                          {charSections.map(NavTab)}
                          <Box my={1} mx={1} height="1px" backgroundColor="rgba(255,255,255,0.15)" />
                          {systemSections.map(NavTab)}
                        </Tabs>
                      </Section>
                    </Stack.Item>
                    {data.preview_map_front && data.preview_map_side ? (
                      <Stack.Item>
                        <Stack>
                          <Stack.Item grow basis={0}>
                            <div
                              ref={frontBoxRef}
                              style={{
                                position: 'relative',
                                width: '100%',
                                aspectRatio: '1 / 1',
                                backgroundColor: backdropColor || '#0d0d0d',
                              }}
                            >
                              {previewMiniZoom > 0 ? (
                                <ByondUi
                                  key={data.preview_map_front}
                                  width="100%"
                                  height="100%"
                                  params={{
                                    id: data.preview_map_front,
                                    type: 'map',
                                    zoom: previewMiniZoom,
                                    'zoom-mode': 'distort',
                                    'background-color':
                                      backdropColor || '#0d0d0d',
                                  }}
                                />
                              ) : null}
                            </div>
                            <Box
                              color="label"
                              textAlign="center"
                              style={{ fontSize: '10px', lineHeight: '14px' }}
                            >
                              Front
                            </Box>
                          </Stack.Item>
                          <Stack.Item grow basis={0}>
                            <div
                              ref={sideBoxRef}
                              style={{
                                position: 'relative',
                                width: '100%',
                                aspectRatio: '1 / 1',
                                backgroundColor: backdropColor || '#0d0d0d',
                              }}
                            >
                              {previewMiniZoom > 0 ? (
                                <ByondUi
                                  key={data.preview_map_side}
                                  width="100%"
                                  height="100%"
                                  params={{
                                    id: data.preview_map_side,
                                    type: 'map',
                                    zoom: previewMiniZoom,
                                    'zoom-mode': 'distort',
                                    'background-color':
                                      backdropColor || '#0d0d0d',
                                  }}
                                />
                              ) : null}
                            </div>
                            <Box
                              color="label"
                              textAlign="center"
                              style={{ fontSize: '10px', lineHeight: '14px' }}
                            >
                              Side
                            </Box>
                          </Stack.Item>
                        </Stack>
                      </Stack.Item>
                    ) : null}
                  </Stack>
                </Stack.Item>

                <Stack.Item basis="520px">
                  <Section fill title="Looking Glass">
                    <Stack vertical fill>
                      <Stack.Item grow>
                        <Box
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            height: '100%',
                            width: '100%',
                          }}
                        >
                        <div
                          ref={dollBoxRef}
                          style={{
                            position: 'relative',
                            width: '82%',
                            aspectRatio: '0.82 / 1',
                            maxHeight: '100%',
                            backgroundColor: backdropColor || '#0d0d0d',
                          }}
                        >
                        {data.preview_map && previewZoom > 0 ? (
                          <ByondUi
                            key={data.preview_map}
                            width="100%"
                            height="100%"
                            params={{
                              id: data.preview_map,
                              type: 'map',
                              zoom: previewZoom,
                              'zoom-mode': 'distort',
                              'background-color': backdropColor || '#0d0d0d',
                            }}
                          />
                        ) : (
                          <Box
                            style={{
                              position: 'absolute',
                              top: 0,
                              left: 0,
                              width: '100%',
                              height: '100%',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                            }}
                          >
                            <Icon name="user" size={6} color="label" />
                          </Box>
                        )}
                        </div>
                        </Box>
                      </Stack.Item>
                    <Stack.Item>
                      <Stack mb={0.5}>
                        <Stack.Item grow>
                          <Button
                            fluid
                            textAlign="center"
                            icon="arrow-left"
                            tooltip="Rotate left"
                            onClick={() => doPref('character_setup_preview_rotate', undefined, { rotate: 'left' })}
                          />
                        </Stack.Item>
                        <Stack.Item>
                          <Box color="label" style={{ lineHeight: '24px' }}>
                            Rotate
                          </Box>
                        </Stack.Item>
                        <Stack.Item grow>
                          <Button
                            fluid
                            textAlign="center"
                            icon="arrow-right"
                            tooltip="Rotate right"
                            onClick={() => doPref('character_setup_preview_rotate', undefined, { rotate: 'right' })}
                          />
                        </Stack.Item>
                      </Stack>
                      <Button
                        fluid
                        mb={0.5}
                        icon={asBool(data.preview_underwear) ? 'check-square' : 'square'}
                        selected={asBool(data.preview_underwear)}
                        onClick={() => doPref('character_setup_preview_layer', undefined, { layer: 'underwear' })}
                      >
                        Underwear Layer
                      </Button>
                      <Button
                        fluid
                        mb={0.5}
                        icon={asBool(data.preview_clothes) ? 'check-square' : 'square'}
                        selected={asBool(data.preview_clothes)}
                        onClick={() => doPref('character_setup_preview_layer', undefined, { layer: 'clothes' })}
                      >
                        Work Clothes Layer
                      </Button>
                      <Button
                        fluid
                        icon="dice"
                        onClick={() => doPref('randomiseappearanceprefs')}
                      >
                        Randomise Appearance
                      </Button>
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>

              <Stack.Item grow basis={0}>
                <Section fill scrollable>{renderActiveSection()}</Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          <Stack.Item>
            <Section>
              <Stack align="center">
                <Stack.Item grow>
                  <Stack>
                    <Stack.Item>
                      <FooterSummary icon="shield-alt" label="Class" value={data.high_job} onClick={() => setActiveSection('gameplay')} />
                    </Stack.Item>
                    <Stack.Item>
                      <FooterSummary icon="trophy" label="Triumphs" value={data.triumphs} onClick={() => setActiveSection('gameplay')} />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
                <Stack.Item>
                  <Button icon="dice" tooltip="Randomise Appearance" onClick={() => doPref('randomiseappearanceprefs')}>
                    Randomise
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button icon="undo" tooltip="Undo from save" onClick={() => doPref('load')}>
                    Undo
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button icon="save" tooltip="Save" onClick={() => doPref('save')}>
                    Save
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button icon="check" color="green" tooltip="Done" onClick={() => doPref('finished')}>
                    Done
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
        </Box>
      </Window.Content>
    </Window>
  );
};

export default PreferencesMenu;

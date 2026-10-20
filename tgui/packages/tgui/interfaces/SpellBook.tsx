import { type ReactNode, useState } from 'react';
import {
  Box,
  Button,
  Collapsible,
  DmIcon,
  Icon,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Act = (action: string, params?: Record<string, unknown>) => void;

type Page = 'learn' | 'stats' | 'prepared';

type Track = {
  id: string;
  name: string;
  level: number;
  rank: string;
  modifiers?: {
    cost: number;
    castSpeed: number;
    magnitude: number;
  } | null;
};

type SpellEntry = {
  path: string;
  name: string;
  desc: string;
  technique: string | null;
  form: string | null;
  level: number;
  // null for legacy mana spells, 0 for cantrips, 1-5 for slot spells.
  slotLevel: number | null;
  formCost: number;
  techniqueCost: number;
  unlocked: BooleanLike;
  canLearn: BooleanLike;
  canUnlearn: BooleanLike;
  needsPreparation: BooleanLike;
  prepared: BooleanLike;
  icon: string;
  iconState: string;
  heretical: BooleanLike;
  prerequisites?: { name: string; known: BooleanLike }[];
};

type SlotPool = {
  name: string;
  current: number;
  max: number;
  rest: string;
};

type SlotInfo = {
  archetype: string;
  hasLadder: BooleanLike;
  skillName: string;
  rank: number;
  rankName: string;
  skillValue: number;
  nextRankName: string | null;
  nextRankValue: number | null;
  current: number[];
  maximum: number[];
  nextMaximum: number[] | null;
  pactLevel: number;
  shortRests: number;
  shortRestsMax: number;
  unlimitedShortRests: BooleanLike;
  longRestIn: string | null;
  pools: SlotPool[];
};

type SpellBookData = {
  slotInfo?: SlotInfo | null;
  unspentFormPoints: number;
  unspentTechniquePoints: number;
  unlearnMode: BooleanLike;
  usesPreparation: BooleanLike;
  preparedCount: number;
  maxPrepared: number;
  canPrepare: BooleanLike;
  bookAtHand: BooleanLike;
  inCombatMode: BooleanLike;
  techniqueLevels: Track[];
  formLevels: Track[];
  spells: SpellEntry[];
};

type SpellBookStatic = {
  techniques: string[];
  forms: string[];
};

const formatModifierPart = (label: string, multiplier: number) => {
  if (multiplier === 1) return null;
  const pct = Math.round((multiplier - 1) * 100);
  return `${pct > 0 ? '+' : ''}${pct}% ${label}`;
};

const formatModifierWhole = (label: string, amount: number) => {
  if (amount === 0) return null;
  return `${amount > 0 ? '+' : ''}${amount} ${label}`;
};

const formatModifiers = (modifiers: Track['modifiers']) => {
  if (!modifiers) return null;
  const parts = [
    formatModifierPart('mana cost', modifiers.cost),
    formatModifierPart('cast speed', modifiers.castSpeed),
    formatModifierWhole('magnitude', modifiers.magnitude),
  ].filter(Boolean);
  return parts.length > 0 ? parts.join(', ') : null;
};

const SpellSprite = (props: { icon: string; iconState: string }) => {
  const { icon, iconState } = props;
  if (!icon || !iconState) {
    return null;
  }
  return (
    <DmIcon
      fallback={<Icon name="wand-magic-sparkles" size={1.4} color="gray" />}
      icon={icon}
      icon_state={iconState}
      height={2}
      width={2}
    />
  );
};

const costLabel = (spell: SpellEntry) => {
  const parts: string[] = [];
  if (spell.formCost > 0) {
    parts.push(`${spell.formCost} form pt${spell.formCost === 1 ? '' : 's'}`);
  }
  if (spell.techniqueCost > 0) {
    parts.push(
      `${spell.techniqueCost} technique pt${spell.techniqueCost === 1 ? '' : 's'}`,
    );
  }
  return parts.length > 0 ? parts.join(', ') : 'Free';
};

const slotLabel = (slotLevel: number | null) => {
  if (typeof slotLevel !== 'number') {
    return null;
  }
  return slotLevel === 0 ? 'Cantrip' : `L${slotLevel}`;
};

// "L1 4, L2 3, L3 2" for a ladder row; levels without slots are skipped.
const ladderText = (row: number[] | null | undefined) => {
  if (!row) {
    return 'none';
  }
  const parts = row
    .map((count, index) => (count > 0 ? `L${index + 1} ${count}` : null))
    .filter(Boolean);
  return parts.length ? parts.join(', ') : 'none';
};

const slotSummaryText = (info: SlotInfo) => {
  const skill = `${info.skillName} (${info.rankName}, ${info.skillValue})`;
  if (!info.hasLadder) {
    return `${info.archetype}; powers follow ${skill}`;
  }
  const next = info.nextRankName
    ? `; ${info.nextRankName} at ${info.nextRankValue} gives ${ladderText(info.nextMaximum)}`
    : '';
  return `${info.archetype}; slots follow ${skill}: ${ladderText(info.maximum)}${next}`;
};

const SlotSection = (props: { info: SlotInfo }) => {
  const { info } = props;
  const levels = info.maximum
    .map((max, index) =>
      max > 0 ? `L${index + 1} ${info.current[index]}/${max}` : null,
    )
    .filter(Boolean)
    .join(', ');
  return (
    <Section title="Spell Slots" fill scrollable>
      <LabeledList>
        <LabeledList.Item label="Archetype">{info.archetype}</LabeledList.Item>
        <LabeledList.Item label="Governing skill">
          {info.skillName} at {info.skillValue}
        </LabeledList.Item>
        <LabeledList.Item label="Rank">{info.rankName}</LabeledList.Item>
        {!!info.hasLadder && (
          <LabeledList.Item label="Slots now">
            {levels || 'none'}
          </LabeledList.Item>
        )}
        {!!info.hasLadder && !!info.pactLevel && (
          <LabeledList.Item label="Pact level">
            {info.pactLevel}, every slot refills on a short rest
          </LabeledList.Item>
        )}
        {!!info.hasLadder && info.nextRankName && (
          <LabeledList.Item label="Next rank">
            {info.nextRankName} at {info.skillName} {info.nextRankValue}:{' '}
            {ladderText(info.nextMaximum)}
          </LabeledList.Item>
        )}
        {!!info.hasLadder && !info.nextRankName && (
          <LabeledList.Item label="Next rank">
            None, the ladder is complete
          </LabeledList.Item>
        )}
        <LabeledList.Item label="Short rests">
          {info.unlimitedShortRests
            ? 'unlimited'
            : `${info.shortRests} / ${info.shortRestsMax}`}
        </LabeledList.Item>
        <LabeledList.Item label="Long rest">
          {info.longRestIn ? `ready in ${info.longRestIn}` : 'ready'}
        </LabeledList.Item>
        {info.pools.map((pool) => (
          <LabeledList.Item key={pool.name} label={pool.name}>
            {pool.current} / {pool.max}, refilled by a {pool.rest}
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Section>
  );
};

const Badge = (props: { color: string; children: ReactNode }) => {
  const { color, children } = props;
  return (
    <Box
      as="span"
      ml={1}
      px={0.5}
      fontSize="0.8em"
      color={color}
      style={{ border: '1px solid currentColor', borderRadius: '3px' }}
    >
      {children}
    </Box>
  );
};

const SpellName = (props: { spell: SpellEntry; showPrepared: boolean }) => {
  const { spell, showPrepared } = props;
  const slot = slotLabel(spell.slotLevel);
  return (
    <Box>
      <Box as="span" bold color={spell.heretical ? 'red' : undefined}>
        {spell.name}
        {!!spell.heretical && ' (FORBIDDEN)'}
      </Box>
      {slot && (
        <Badge color={spell.slotLevel === 0 ? 'label' : 'teal'}>{slot}</Badge>
      )}
      {showPrepared && <Badge color="good">Prepared</Badge>}
    </Box>
  );
};

const SpellCard = (props: {
  spell: SpellEntry;
  unlearnMode: BooleanLike;
  usesPreparation: BooleanLike;
  onLearn: (path: string) => void;
  onUnlearn: (path: string) => void;
}) => {
  const { spell, unlearnMode, usesPreparation, onLearn, onUnlearn } = props;
  const status = spell.unlocked
    ? 'unlocked'
    : spell.canLearn
      ? 'available'
      : 'locked';
  // Innate casters and always-ready spells report prepared too, so mark only preparable ones.
  const showPrepared =
    !!usesPreparation &&
    !!spell.needsPreparation &&
    !!spell.unlocked &&
    !!spell.prepared;
  const prerequisites = spell.prerequisites || [];
  const missing = prerequisites.filter((p) => !p.known).map((p) => p.name);
  const learnTooltip = missing.length
    ? `Needs ${missing.join(', ')} first`
    : undefined;

  return (
    <Box
      className={`SpellBook__node SpellBook__node--${status}`}
      backgroundColor="rgba(255,255,255,0.03)"
      p={1}
      mb={0.5}
    >
      <Stack align="center">
        <Stack.Item>
          <SpellSprite icon={spell.icon} iconState={spell.iconState} />
        </Stack.Item>
        <Stack.Item grow>
          <SpellName spell={spell} showPrepared={showPrepared} />
          <Box color="label" fontSize="0.9em">
            {spell.desc}
          </Box>
          <Box fontSize="0.85em" color="label">
            Cost: {costLabel(spell)}
            {spell.level > 0 &&
              (spell.form || spell.technique) &&
              ` · Requires ${spell.form || spell.technique} ${spell.level}`}
          </Box>
          {prerequisites.length > 0 && (
            <Box fontSize="0.85em" color={missing.length ? 'bad' : 'label'}>
              Needs:{' '}
              {prerequisites
                .map((p) => (p.known ? p.name : `${p.name} (not known)`))
                .join(', ')}
            </Box>
          )}
        </Stack.Item>
        <Stack.Item>
          {unlearnMode ? (
            <Button
              color="bad"
              disabled={!spell.canUnlearn}
              onClick={() => onUnlearn(spell.path)}
            >
              Unlearn
            </Button>
          ) : spell.unlocked ? (
            <Icon name="check" color="good" />
          ) : (
            <Button
              disabled={!spell.canLearn}
              tooltip={learnTooltip}
              onClick={() => onLearn(spell.path)}
            >
              Learn
            </Button>
          )}
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const TrackSummary = (props: { track: Track | undefined; label: string }) => {
  const { track, label } = props;
  if (!track) {
    return null;
  }
  return (
    <Box bold mb={1}>
      {label} - {track.rank} ({track.level})
    </Box>
  );
};

const InvestRow = (props: {
  track: Track;
  disabled: boolean;
  onInvest: (id: string) => void;
}) => {
  const { track, disabled, onInvest } = props;
  const modifierText = formatModifiers(track.modifiers);

  return (
    <Stack align="center" mb={0.5} className="SpellBook__invest-row">
      <Stack.Item grow>
        <Box bold>{track.name}</Box>
        <Box color="label" fontSize="0.9em">
          {track.rank} - Level {track.level}
        </Box>
        {modifierText && (
          <Box color="average" fontSize="0.85em">
            {modifierText}
          </Box>
        )}
      </Stack.Item>
      <Stack.Item>
        <Button disabled={disabled} onClick={() => onInvest(track.id)}>
          Invest 1 point
        </Button>
      </Stack.Item>
    </Stack>
  );
};

const StatsPage = (props: {
  unspentFormPoints: number;
  unspentTechniquePoints: number;
  techniqueLevels: Track[];
  formLevels: Track[];
  slotInfo?: SlotInfo | null;
  act: Act;
}) => {
  const {
    unspentFormPoints,
    unspentTechniquePoints,
    techniqueLevels,
    formLevels,
    slotInfo,
    act,
  } = props;

  return (
    <Stack fill mt={1}>
      {slotInfo && (
        <Stack.Item grow>
          <SlotSection info={slotInfo} />
        </Stack.Item>
      )}
      <Stack.Item grow>
        <Section
          title="Techniques"
          fill
          scrollable
          buttons={
            <Box color={unspentTechniquePoints > 0 ? 'good' : 'label'}>
              {unspentTechniquePoints} pt
              {unspentTechniquePoints === 1 ? '' : 's'}
            </Box>
          }
        >
          {techniqueLevels.map((track) => (
            <InvestRow
              key={track.id}
              track={track}
              disabled={unspentTechniquePoints < 1}
              onInvest={(id) => act('invest_technique', { technique: id })}
            />
          ))}
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section
          title="Forms"
          fill
          scrollable
          buttons={
            <Box color={unspentFormPoints > 0 ? 'good' : 'label'}>
              {unspentFormPoints} pt{unspentFormPoints === 1 ? '' : 's'}
            </Box>
          }
        >
          {formLevels.map((track) => (
            <InvestRow
              key={track.id}
              track={track}
              disabled={unspentFormPoints < 1}
              onInvest={(id) => act('invest_form', { form: id })}
            />
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const FORM_WARNINGS: Record<string, ReactNode> = {
  Death: (
    <>
      The use of Death Magic is frowned upon by The Divine Pantheon, you should
      expect great scrutiny when wielding it.
      <br />
      Certain spells within this form are heretical under The Ten and if
      recognised may lead to excommunication or execution.
    </>
  ),
  Hemomancy: (
    <>
      The use of Hemomancy is considered heresy by The Divine Pantheon, and is
      frowned upon even by The Four.
      <br />
      Attempting to use Hemomancy without the proper instruction will be
      inefficient and potentially dangerous.
    </>
  ),
};

const LearnPage = (props: {
  techniques: string[];
  forms: string[];
  techniqueLevels: Track[];
  formLevels: Track[];
  spells: SpellEntry[];
  unlearnMode: BooleanLike;
  usesPreparation: BooleanLike;
  act: Act;
}) => {
  const {
    techniques,
    forms,
    techniqueLevels,
    formLevels,
    spells,
    unlearnMode,
    usesPreparation,
    act,
  } = props;

  const [activeForm, setActiveForm] = useState<string>(forms[0]);
  const [activeTechnique, setActiveTechnique] = useState<string | null>(null);

  const formTrack = formLevels.find((f) => f.id === activeForm);
  const warning = FORM_WARNINGS[activeForm];
  const spellsInForm = spells.filter((spell) => spell.form === activeForm);

  const techniqueSpells = spellsInForm.filter((spell) => spell.technique);
  const techniquelessSpells = spellsInForm.filter((spell) => !spell.technique);

  const relevantTechniques = techniques.filter((technique) =>
    techniqueSpells.some((spell) => spell.technique === technique),
  );
  const currentTechnique =
    activeTechnique && relevantTechniques.includes(activeTechnique)
      ? activeTechnique
      : relevantTechniques[0];
  const techniqueTrack = techniqueLevels.find((t) => t.id === currentTechnique);
  const visibleTechniqueSpells = techniqueSpells.filter(
    (spell) => spell.technique === currentTechnique,
  );

  const onLearn = (path: string) => act('learn_spell', { path });
  const onUnlearn = (path: string) => act('unlearn_spell', { path });

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Stack align="center">
          <Stack.Item grow>
            <Tabs>
              {forms.map((form) => {
                const track = formLevels.find((f) => f.id === form);
                return (
                  <Tabs.Tab
                    key={form}
                    selected={activeForm === form}
                    onClick={() => {
                      setActiveForm(form);
                      setActiveTechnique(null);
                    }}
                  >
                    {form}
                    {track ? ` (${track.level})` : ''}
                  </Tabs.Tab>
                );
              })}
            </Tabs>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Own item, so an open warning shrinks the columns instead of clipping them. */}
      {!!warning && (
        <Stack.Item>
          <Collapsible title="Warning">{warning}</Collapsible>
        </Stack.Item>
      )}

      <Stack.Item grow style={{ minHeight: 0 }}>
        <Stack fill>
          <Stack.Item grow={3} style={{ minHeight: 0 }}>
            <Section title="Techniques" fill>
              <Stack vertical fill>
                <Stack.Item>
                  <TrackSummary track={formTrack} label={activeForm} />

                  {relevantTechniques.length > 0 && (
                    <Tabs mb={1}>
                      {relevantTechniques.map((technique) => (
                        <Tabs.Tab
                          key={technique}
                          selected={currentTechnique === technique}
                          onClick={() => setActiveTechnique(technique)}
                        >
                          {technique}
                        </Tabs.Tab>
                      ))}
                    </Tabs>
                  )}

                  <TrackSummary
                    track={techniqueTrack}
                    label={currentTechnique || ''}
                  />
                </Stack.Item>

                <Stack.Item grow style={{ minHeight: 0, overflowY: 'auto' }}>
                  {visibleTechniqueSpells.length === 0 && (
                    <Box color="label" italic>
                      No technique-gated spells here yet.
                    </Box>
                  )}
                  {visibleTechniqueSpells.map((spell) => (
                    <SpellCard
                      key={spell.path}
                      spell={spell}
                      unlearnMode={unlearnMode}
                      usesPreparation={usesPreparation}
                      onLearn={onLearn}
                      onUnlearn={onUnlearn}
                    />
                  ))}
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item grow={2} style={{ minHeight: 0 }}>
            <Section title={`Techniqueless ${activeForm}`} fill scrollable>
              {techniquelessSpells.length === 0 && (
                <Box color="label" italic>
                  No techniqueless {activeForm} spells.
                </Box>
              )}
              {techniquelessSpells.map((spell) => (
                <SpellCard
                  key={spell.path}
                  spell={spell}
                  unlearnMode={unlearnMode}
                  usesPreparation={usesPreparation}
                  onLearn={onLearn}
                  onUnlearn={onUnlearn}
                />
              ))}
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const PreparedRow = (props: {
  spell: SpellEntry;
  canPrepare: BooleanLike;
  blockReason: string | null;
  onToggle: (path: string, state: number) => void;
}) => {
  const { spell, canPrepare, blockReason, onToggle } = props;

  return (
    <Box
      className="SpellBook__node"
      backgroundColor="rgba(255,255,255,0.03)"
      p={1}
      mb={0.5}
    >
      <Stack align="center">
        <Stack.Item>
          <SpellSprite icon={spell.icon} iconState={spell.iconState} />
        </Stack.Item>
        <Stack.Item grow>
          <SpellName spell={spell} showPrepared={false} />
          <Box color="label" fontSize="0.9em">
            {spell.desc}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={spell.prepared}
            disabled={!canPrepare}
            tooltip={blockReason}
            onClick={() => onToggle(spell.path, spell.prepared ? 0 : 1)}
          >
            Prepared
          </Button.Checkbox>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const PreparedPage = (props: {
  spells: SpellEntry[];
  preparedCount: number;
  maxPrepared: number;
  canPrepare: BooleanLike;
  bookAtHand: BooleanLike;
  inCombatMode: BooleanLike;
  act: Act;
}) => {
  const {
    spells,
    preparedCount,
    maxPrepared,
    canPrepare,
    bookAtHand,
    inCombatMode,
    act,
  } = props;

  const blockReason = canPrepare
    ? null
    : inCombatMode
      ? 'Leave combat mode to prepare spells'
      : !bookAtHand
        ? 'Your grimoire must be at hand'
        : null;

  // Sorted by slot level then name, so rows stay put while toggling.
  const preparable = spells
    .filter((spell) => spell.unlocked && spell.needsPreparation)
    .sort(
      (a, b) =>
        (a.slotLevel ?? 0) - (b.slotLevel ?? 0) || a.name.localeCompare(b.name),
    );

  const onToggle = (path: string, state: number) =>
    act('prepare_spell', { path, state });

  return (
    <Section
      title={`Prepared ${preparedCount} / ${maxPrepared}`}
      fill
      scrollable
    >
      {blockReason && <NoticeBox>{blockReason}</NoticeBox>}
      {preparable.length === 0 && (
        <Box color="label" italic>
          No learned spells need preparing.
        </Box>
      )}
      {preparable.map((spell) => (
        <PreparedRow
          key={spell.path}
          spell={spell}
          canPrepare={canPrepare}
          blockReason={blockReason}
          onToggle={onToggle}
        />
      ))}
    </Section>
  );
};

export const SpellBook = () => {
  const { act, data } = useBackend<SpellBookData & SpellBookStatic>();
  const {
    slotInfo,
    unspentFormPoints,
    unspentTechniquePoints,
    unlearnMode,
    usesPreparation,
    preparedCount = 0,
    maxPrepared = 0,
    canPrepare,
    bookAtHand,
    inCombatMode,
    techniques = [],
    forms = [],
    techniqueLevels = [],
    formLevels = [],
    spells = [],
  } = data;

  const [page, setPage] = useState<Page>('learn');
  // Falls back to Learn when preparation is switched off while its tab is open.
  const currentPage = page === 'prepared' && !usesPreparation ? 'learn' : page;

  return (
    <Window width={900} height={800} title="Spellcraft">
      <Window.Content scrollable={false}>
        <Stack vertical fill>
          <Stack.Item>
            <Section
              title="Spellcraft"
              buttons={
                <Stack>
                  <Stack.Item>
                    <Box bold color={unspentFormPoints > 0 ? 'good' : 'label'}>
                      Form: {unspentFormPoints}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Box
                      bold
                      color={unspentTechniquePoints > 0 ? 'good' : 'label'}
                    >
                      Technique: {unspentTechniquePoints}
                    </Box>
                  </Stack.Item>
                </Stack>
              }
            >
              {slotInfo && (
                <Box color="label" mb={1}>
                  <Icon name="layer-group" mr={1} />
                  {slotSummaryText(slotInfo)}
                </Box>
              )}
              <Tabs m="0px">
                <Tabs.Tab
                  selected={currentPage === 'learn'}
                  onClick={() => setPage('learn')}
                >
                  <Icon name="book-open" mr={1} />
                  Learn
                </Tabs.Tab>
                <Tabs.Tab
                  selected={currentPage === 'stats'}
                  onClick={() => setPage('stats')}
                >
                  <Icon name="chart-simple" mr={1} />
                  Stats
                </Tabs.Tab>
                {!!usesPreparation && (
                  <Tabs.Tab
                    selected={currentPage === 'prepared'}
                    onClick={() => setPage('prepared')}
                  >
                    <Icon name="scroll" mr={1} />
                    Prepared
                  </Tabs.Tab>
                )}
              </Tabs>
            </Section>
          </Stack.Item>

          <Stack.Item grow style={{ minHeight: 0 }}>
            {currentPage === 'learn' && (
              <LearnPage
                techniques={techniques}
                forms={forms}
                techniqueLevels={techniqueLevels}
                formLevels={formLevels}
                spells={spells}
                unlearnMode={unlearnMode}
                usesPreparation={usesPreparation}
                act={act}
              />
            )}
            {currentPage === 'stats' && (
              <StatsPage
                unspentFormPoints={unspentFormPoints}
                unspentTechniquePoints={unspentTechniquePoints}
                techniqueLevels={techniqueLevels}
                formLevels={formLevels}
                slotInfo={slotInfo}
                act={act}
              />
            )}
            {currentPage === 'prepared' && (
              <PreparedPage
                spells={spells}
                preparedCount={preparedCount}
                maxPrepared={maxPrepared}
                canPrepare={canPrepare}
                bookAtHand={bookAtHand}
                inCombatMode={inCombatMode}
                act={act}
              />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

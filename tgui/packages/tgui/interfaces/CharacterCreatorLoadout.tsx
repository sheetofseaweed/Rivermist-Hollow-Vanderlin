import { type ReactNode, useState } from 'react';
import { Box, Icon } from 'tgui-core/components';

import { useBackend } from '../backend';
import { dragStartHandler } from '../drag';
import { suspendStart } from '../events/handlers/suspense';
import { Window } from '../layouts';
import {
  Btn,
  CSS,
  Frame,
  Select,
  Swatch,
  Tip,
  TipLayer,
} from './CharacterCreator';
import {
  type CharacterCreatorStrings,
  characterCreatorStrings,
} from './CharacterCreator.i18n';

// Loadout window of the Character Creator (modular_rmh/modular/character_creator).
// Items: pick up to 10 loadout items. Equip Items: wear them in paper doll slots.
// Stash: items left unworn wait in the stash or, if marked, go into the bags.

type Booleanish = boolean | number;

type ItemInfo = {
  desc?: string;
  weight?: number;
  armorClassLabel?: string;
  weaponDamage?: { force: number };
  weaponCategory?: string;
  intents?: { name: string; grip: string }[];
  specialAttack?: { name: string; desc: string };
  tags?: string[];
};

type CatalogItem = {
  name: string;
  desc: string;
  point_cost: number;
  typepath: string;
  icon: string;
  nobility_locked: Booleanish;
  category: string;
  fits: string[];
  info: ItemInfo;
};

type LoadoutSlot = {
  slot: number;
  item_name: string | null;
  typepath: string | null;
  point_cost: number;
  custom_name: string | null;
  custom_desc: string | null;
  custom_hex: string | null;
};

type Preset = {
  slot: number;
  name: string | null;
  role: string | null;
  empty: Booleanish;
  summary: string;
};

type LoadoutData = {
  lang: string;
  catalog: CatalogItem[];
  roles: string[];
  slots: LoadoutSlot[];
  points: { total: number; spent: number; remaining: number };
  presets: Preset[];
  equip: Record<string, string>;
  bag: string[];
};

type Page = 'items' | 'equip' | 'stash';

const CATEGORIES = [
  'all',
  'head',
  'face',
  'accessories',
  'cloaks',
  'armor',
  'clothing',
  'weapons',
  'misc',
];

/** Paper doll layout from the plan, three columns. */
const DOLL: string[] = [
  'mask',
  'head',
  'mouth',
  'backr',
  'cloak',
  'backl',
  'neck',
  'armor',
  'wrists',
  'ring',
  'shirt',
  'gloves',
  'beltr',
  'belt',
  'beltl',
  'rhand',
  'pants',
  'lhand',
  'undies',
  'shoes',
  'piercing',
];
const UNDIES = [
  'under_top',
  'under_bottom',
  'undershirt',
  'socks',
  'garter',
  'armsleeves',
];
const PIERCINGS = ['earring_l', 'earring_r', 'choker'];
const HANDS = ['rhand', 'lhand'];

const LOADOUT_CSS = `
.ccl { grid-template-columns: minmax(0, 1fr); grid-template-rows: auto minmax(0, 1fr) auto; grid-template-areas: "top" "content" "foot"; }
.ccl-top { display: flex; align-items: center; gap: 6px; cursor: move; }
.ccl-top .cc-btn, .ccl-top .cc-dd, .ccl-top input { cursor: pointer; }
.ccl-title { font-family: var(--cc-serif); color: var(--cc-gold); font-size: 16px; letter-spacing: 1px; padding: 0 8px; white-space: nowrap; }
.ccl-body { display: grid; grid-template-columns: minmax(230px, 0.85fr) minmax(320px, 2fr); gap: 8px; min-height: 0; height: 100%; }
.ccl-pane { min-height: 0; display: flex; flex-direction: column; padding: 8px; }
.ccl-items { display: flex; flex-wrap: wrap; justify-content: center; gap: 8px; }
.ccl-items > * { flex: 0 0 96px; width: 96px; box-sizing: border-box; }
.ccl-item {
  position: relative; min-height: 104px; padding: 6px 4px;
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px;
  border: 1px solid #3a3024; background: radial-gradient(circle at 50% 35%, #2a2219, #15110d);
  cursor: pointer; border-radius: 4px;
}
.ccl-item:hover { border-color: var(--cc-silver); }
.ccl-item.chosen { border-color: var(--cc-gold); box-shadow: 0 0 8px rgba(201,164,92,0.5); }
.ccl-item.blocked { opacity: 0.4; }
.ccl-cost { position: absolute; top: 3px; right: 6px; font-size: 11px; color: var(--cc-gold); font-family: var(--cc-serif); }
.ccl-name { font-size: 11px; text-align: center; line-height: 1.15; max-height: 26px; overflow: hidden; }
.ccl-icon { width: 56px; height: 56px; display: flex; align-items: center; justify-content: center; }
.ccl-icon > div { transform: scale(1.7); image-rendering: pixelated; }
.ccl-icon.small { width: 36px; height: 36px; }
.ccl-icon.small > div { transform: scale(1.05); }
.ccl-slot-card { border: 1px solid #5a4630; background: linear-gradient(180deg, #2a2117, #1c1711); padding: 6px; margin-bottom: 6px; }
.ccl-doll { display: grid; grid-template-columns: repeat(3, minmax(74px, 1fr)); gap: 8px; padding: 12px; background: linear-gradient(180deg, #2e2416, #191410); position: relative; }
.ccl-eq {
  position: relative; min-height: 78px; border: 1px solid #3a3024; background: #1b1d22; border-radius: 6px;
  display: flex; align-items: center; justify-content: center; cursor: pointer;
  font-family: var(--cc-serif); color: #cdbb94;
}
.ccl-eq:hover { border-color: var(--cc-silver); }
.ccl-eq.has-fit { background: #3a3530; }
.ccl-eq.active { border-color: #e8c547; box-shadow: 0 0 8px rgba(232,197,71,0.5); }
.ccl-eq-label { position: absolute; top: 4px; left: 6px; font-size: 10px; color: #cdbb94; font-family: Verdana, sans-serif; }
.ccl-eq-count { position: absolute; bottom: 3px; right: 6px; font-size: 11px; color: #e6dccb; }
.ccl-eq-tag { position: absolute; bottom: 3px; right: 6px; font-size: 10px; color: #a9d68a; font-weight: bold; }
.ccl-eq-tagl { position: absolute; bottom: 3px; left: 6px; font-size: 10px; color: #e2a25a; }
.ccl-pop {
  position: absolute; z-index: 30; left: 8px; right: 8px; top: 8px;
  background: #0d0b09; border: 1px solid var(--cc-gold-dim); box-shadow: 0 6px 20px rgba(0,0,0,0.85);
  padding: 8px; max-height: calc(100% - 16px); display: flex; flex-direction: column;
}
.ccl-pop-head { display: flex; align-items: center; gap: 6px; margin-bottom: 6px; }
.ccl-pop-title { font-family: var(--cc-serif); color: var(--cc-text); font-size: 15px; }
.ccl-pop-grid { display: flex; flex-wrap: wrap; justify-content: center; gap: 6px; }
.ccl-pop-grid > * { flex: 0 0 90px; width: 90px; box-sizing: border-box; }
.ccl-mini { display: grid; grid-template-columns: repeat(3, minmax(74px, 1fr)); gap: 8px; }
.ccl-foot { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; padding: 6px 8px; }
.ccl-row-item { display: flex; align-items: center; gap: 8px; padding: 6px; border: 1px solid #5a4630; background: linear-gradient(180deg, #2a2117, #1c1711); margin-bottom: 6px; }
.ccl-tip-line { margin-top: 3px; }
.ccl-tip-damage { color: #8fc97a; font-weight: bold; font-size: 13px; }
.ccl-tip-meta { color: #7fa7c9; }
`;

const iconBox = (item: CatalogItem | undefined, small?: boolean) => (
  <div className={`ccl-icon ${small ? 'small' : ''}`}>
    {item?.icon ? <Box className={item.icon} /> : <Icon name="box" />}
  </div>
);

/** Tooltip body shaped like the Examine Closer item tooltip. */
const itemTipBody = (
  item: CatalogItem,
  L: CharacterCreatorStrings,
  custom?: LoadoutSlot,
) => {
  const info = item.info || {};
  return (
    <>
      {info.weaponDamage ? (
        <div className="ccl-tip-damage">
          {info.weaponDamage.force} {L.damage}
        </div>
      ) : null}
      {info.intents?.length ? (
        <div className="ccl-tip-line ccl-tip-meta">
          <Icon name="award" mr={0.5} />
          {info.intents.map((intent) => intent.name.toUpperCase()).join(' · ')}
        </div>
      ) : null}
      <div className="ccl-tip-line">
        {custom?.custom_desc || info.desc || item.desc}
      </div>
      {info.armorClassLabel || info.weaponCategory || info.tags?.length ? (
        <div className="ccl-tip-line ccl-tip-meta">
          {[info.armorClassLabel, info.weaponCategory, ...(info.tags || [])]
            .filter(Boolean)
            .join(' · ')}
        </div>
      ) : null}
      {info.specialAttack ? (
        <div className="ccl-tip-line" style={{ color: '#c9a76f' }}>
          <Icon name="burst" mr={0.5} />
          {info.specialAttack.name}: {info.specialAttack.desc}
        </div>
      ) : null}
      <div className="ccl-tip-line cc-muted">
        {L.cost}: {item.point_cost} {L.points}
        {info.weight ? ` · ${L.weight}: ${info.weight}` : ''}
      </div>
      {custom?.custom_hex ? (
        <div className="ccl-tip-line">
          <Swatch color={custom.custom_hex} /> {L.dyed}
        </div>
      ) : null}
    </>
  );
};

export const CharacterCreatorLoadout = () => {
  const { act, data } = useBackend<LoadoutData>();
  const L = characterCreatorStrings[data.lang === 'ru' ? 'ru' : 'en'];
  const [page, setPage] = useState<Page>('items');
  const [category, setCategory] = useState('all');
  const [search, setSearch] = useState('');
  const [presetSlot, setPresetSlot] = useState(1);
  const [activeSlot, setActiveSlot] = useState<string | null>(null);
  const [miniWindow, setMiniWindow] = useState<'undies' | 'piercing' | null>(
    null,
  );

  const catalog = data.catalog || [];
  const slots = data.slots || [];
  const equip = data.equip || {};
  const bag = data.bag || [];
  const points = data.points || { total: 0, spent: 0, remaining: 0 };
  const presets = data.presets || [];
  const byPath = new Map(catalog.map((item) => [item.typepath, item]));
  const chosen = slots.filter((slot) => slot.typepath);
  const firstEmpty = slots.find((slot) => !slot.typepath)?.slot;
  const loadoutAct = (task: string, extra?: Record<string, unknown>) =>
    act('loadout', { task, ...(extra || {}) });

  const slotOfEquip = (slotId: string) =>
    chosen.find((slot) => equip[String(slot.slot)] === slotId);
  const fitsSlot = (slot: LoadoutSlot, slotId: string) => {
    if (HANDS.includes(slotId)) {
      return true;
    }
    return !!byPath.get(slot.typepath || '')?.fits?.includes(slotId);
  };
  const unequipped = chosen.filter((slot) => !equip[String(slot.slot)]);

  const startDrag = (event: React.MouseEvent<HTMLDivElement>) => {
    const target = event.target as HTMLElement;
    if (
      event.button !== 0 ||
      target.closest('.cc-btn, .cc-dd, input, .cc-search')
    ) {
      return;
    }
    dragStartHandler(event);
  };

  const itemName = (slot: LoadoutSlot) =>
    slot.custom_name || slot.item_name || '';

  // ---- Items page ----

  const renderChosenList = () => (
    <div className="cc-scroll" style={{ flex: 1, minHeight: 0 }}>
      {chosen.length ? (
        chosen.map((slot) => {
          const item = byPath.get(slot.typepath || '');
          return (
            <div className="ccl-slot-card" key={slot.slot}>
              <div className="cc-row" style={{ marginBottom: 4 }}>
                {item ? (
                  <Tip
                    title={itemName(slot)}
                    subtitle={L.loadoutCategories[item.category]}
                    body={itemTipBody(item, L, slot)}
                  >
                    {iconBox(item, true)}
                  </Tip>
                ) : null}
                <div className="cc-grow" style={{ fontWeight: 'bold' }}>
                  {itemName(slot)}
                </div>
                <span className="cc-muted">{slot.point_cost}</span>
              </div>
              <div className="cc-row" style={{ flexWrap: 'wrap' }}>
                <Btn
                  icon="pen"
                  onClick={() => loadoutAct('rename', { slot: slot.slot })}
                >
                  {L.rename}
                </Btn>
                <Btn
                  icon="align-left"
                  onClick={() => loadoutAct('describe', { slot: slot.slot })}
                >
                  {L.describe}
                </Btn>
                <Btn
                  icon="palette"
                  onClick={() => act('dye', { slot: slot.slot })}
                >
                  {slot.custom_hex ? <Swatch color={slot.custom_hex} /> : null}
                  {L.color}
                </Btn>
                <Btn
                  icon="times"
                  className="danger"
                  onClick={() => loadoutAct('clear', { slot: slot.slot })}
                >
                  {L.remove}
                </Btn>
              </div>
            </div>
          );
        })
      ) : (
        <div className="cc-hint">{L.noLoadout}</div>
      )}
    </div>
  );

  const renderItemsPage = () => {
    const lowered = search.trim().toLowerCase();
    // Searching looks through every item, whatever category is open.
    const shown = catalog.filter((item) =>
      lowered
        ? item.name.toLowerCase().includes(lowered) ||
          (item.desc || '').toLowerCase().includes(lowered)
        : category === 'all' || item.category === category,
    );
    return (
      <div className="ccl-body">
        <Frame className="ccl-pane">{renderChosenList()}</Frame>
        <Frame className="ccl-pane">
          <div className="cc-scroll" style={{ flex: 1, minHeight: 0 }}>
            <div className="ccl-items">
              {shown.map((item) => {
                const chosenSlot = chosen.find(
                  (slot) => slot.typepath === item.typepath,
                );
                const blocked =
                  !!item.nobility_locked ||
                  (!chosenSlot &&
                    (item.point_cost > points.remaining || !firstEmpty));
                return (
                  <Tip
                    key={item.typepath}
                    className={`ccl-item ${chosenSlot ? 'chosen' : ''} ${blocked ? 'blocked' : ''}`}
                    title={item.name}
                    subtitle={L.loadoutCategories[item.category]}
                    body={itemTipBody(item, L)}
                    onClick={() => {
                      if (chosenSlot) {
                        loadoutAct('clear', { slot: chosenSlot.slot });
                      } else if (!blocked && firstEmpty) {
                        loadoutAct('select', {
                          slot: firstEmpty,
                          typepath: item.typepath,
                        });
                      }
                    }}
                  >
                    <span className="ccl-cost">{item.point_cost}</span>
                    {iconBox(item)}
                    <div className="ccl-name">{item.name}</div>
                  </Tip>
                );
              })}
            </div>
            {!shown.length ? (
              <div className="cc-hint">{L.noMatches}</div>
            ) : null}
          </div>
        </Frame>
      </div>
    );
  };

  // ---- Equip page ----

  const renderEquipSlot = (slotId: string) => {
    if (slotId === 'undies' || slotId === 'piercing') {
      const subs = slotId === 'undies' ? UNDIES : PIERCINGS;
      const worn = subs.filter((sub) => slotOfEquip(sub)).length;
      return (
        <div
          key={slotId}
          className={`ccl-eq ${miniWindow === slotId ? 'active' : ''}`}
          onClick={() => {
            setMiniWindow(slotId);
            setActiveSlot(null);
          }}
        >
          <span className="ccl-eq-label">{L.equipSlots[slotId]}</span>
          <Icon name={slotId === 'undies' ? 'tshirt' : 'ring'} size={1.5} />
          {worn ? <span className="ccl-eq-count">{worn}</span> : null}
        </div>
      );
    }
    const worn = slotOfEquip(slotId);
    const wornItem = worn ? byPath.get(worn.typepath || '') : undefined;
    const fitCount = unequipped.filter((slot) => fitsSlot(slot, slotId)).length;
    const body = (
      <>
        {wornItem ? (
          <span className="ccl-eq-label">{L.equipSlots[slotId]}</span>
        ) : null}
        {wornItem ? (
          iconBox(wornItem, true)
        ) : (
          <span style={{ opacity: 0.6 }}>{L.equipSlots[slotId]}</span>
        )}
        {wornItem ? <span className="ccl-eq-tag">EQ</span> : null}
        {!wornItem && fitCount ? (
          <span className="ccl-eq-count">{fitCount}</span>
        ) : null}
        {wornItem && worn?.custom_hex ? (
          <span className="ccl-eq-tagl">
            <Swatch color={worn.custom_hex} />
          </span>
        ) : null}
      </>
    );
    const className = `ccl-eq ${fitCount ? 'has-fit' : ''} ${activeSlot === slotId ? 'active' : ''}`;
    const open = () => setActiveSlot(activeSlot === slotId ? null : slotId);
    return wornItem && worn ? (
      <Tip
        key={slotId}
        className={className}
        title={itemName(worn)}
        subtitle={`${L.equipSlots[slotId]} · ${L.equipped}`}
        body={
          <>
            {itemTipBody(wornItem, L, worn)}
            <div className="ccl-tip-line cc-muted">{L.equipMouseHint}</div>
          </>
        }
        onClick={open}
      >
        <div
          style={{ position: 'absolute', inset: 0 }}
          onContextMenu={(event) => {
            event.preventDefault();
            act('dye', { slot: worn.slot });
          }}
        />
        {body}
      </Tip>
    ) : (
      <div key={slotId} className={className} onClick={open}>
        {body}
      </div>
    );
  };

  const renderSlotPopup = () => {
    if (!activeSlot) {
      return null;
    }
    const worn = slotOfEquip(activeSlot);
    const options = unequipped.filter((slot) => fitsSlot(slot, activeSlot));
    return (
      <div className="ccl-pop">
        <div className="ccl-pop-head">
          <div className="cc-grow">
            <div className="ccl-pop-title">{L.equipSlots[activeSlot]}</div>
            <div className="cc-muted" style={{ fontSize: 11 }}>
              {options.length} {L.compatibleItems}
            </div>
          </div>
          <Btn
            disabled={!worn}
            onClick={() =>
              worn && act('equip', { slot: worn.slot, equip: null })
            }
          >
            {L.clearSlot}
          </Btn>
          <Btn onClick={() => setActiveSlot(null)}>{L.close}</Btn>
        </div>
        <div className="cc-scroll" style={{ minHeight: 0 }}>
          <div className="ccl-pop-grid">
            {[...(worn ? [worn] : []), ...options].map((slot) => {
              const item = byPath.get(slot.typepath || '');
              if (!item) {
                return null;
              }
              const isWorn = slot === worn;
              return (
                <Tip
                  key={slot.slot}
                  className={`ccl-item ${isWorn ? 'chosen' : ''}`}
                  title={itemName(slot)}
                  subtitle={isWorn ? L.equipped : L.inBackpack}
                  body={itemTipBody(item, L, slot)}
                  onClick={() => {
                    if (!isWorn) {
                      act('equip', { slot: slot.slot, equip: activeSlot });
                    }
                    setActiveSlot(null);
                  }}
                >
                  {iconBox(item)}
                  <div className="ccl-name">{itemName(slot)}</div>
                </Tip>
              );
            })}
          </div>
        </div>
        <div className="cc-hint">{L.equipPopupHint}</div>
      </div>
    );
  };

  const renderMiniWindow = () => {
    if (!miniWindow) {
      return null;
    }
    const subs = miniWindow === 'undies' ? UNDIES : PIERCINGS;
    return (
      <div className="ccl-pop" style={{ top: 'auto', bottom: 8 }}>
        <div className="ccl-pop-head">
          <div className="ccl-pop-title cc-grow">
            {L.equipSlots[miniWindow]}
          </div>
          <Btn onClick={() => setMiniWindow(null)}>{L.close}</Btn>
        </div>
        <div className="ccl-mini">{subs.map(renderEquipSlot)}</div>
      </div>
    );
  };

  const selectedPreset = presets.find((preset) => preset.slot === presetSlot);

  const renderEquipPage = () => (
    <div
      className="ccl-body"
      style={{ gridTemplateColumns: 'minmax(260px, 1fr) minmax(260px, 1fr)' }}
    >
      <Frame className="ccl-pane" style={{ padding: 0 }}>
        <div className="ccl-doll cc-scroll" style={{ flex: 1 }}>
          {DOLL.map(renderEquipSlot)}
          {renderSlotPopup()}
          {renderMiniWindow()}
        </div>
      </Frame>
      <Frame className="ccl-pane">
        <div className="cc-row" style={{ marginBottom: 8 }}>
          <Select
            value={selectedPreset?.role || ''}
            placeholder={L.chooseRole}
            options={[
              { value: '', label: L.anyRole },
              ...(data.roles || []).map((role) => ({
                value: role,
                label: role,
              })),
            ]}
            onChange={(value) =>
              act('preset_role', { preset: presetSlot, role: value || null })
            }
          />
          <Btn
            className="square primary"
            icon="save"
            title={L.saveForRole}
            onClick={() => loadoutAct('preset_save', { slot: presetSlot })}
          />
        </div>
        <div className="cc-hint" style={{ textAlign: 'left' }}>
          {L.equipHint}
        </div>
        <div className="cc-scroll" style={{ flex: 1, minHeight: 0 }}>
          {unequipped.length ? (
            unequipped.map((slot) => {
              const item = byPath.get(slot.typepath || '');
              return (
                <div className="ccl-row-item" key={slot.slot}>
                  {item ? (
                    <Tip
                      title={itemName(slot)}
                      subtitle={L.loadoutCategories[item.category]}
                      body={itemTipBody(item, L, slot)}
                    >
                      {iconBox(item, true)}
                    </Tip>
                  ) : null}
                  <div className="cc-grow">
                    <div style={{ fontWeight: 'bold' }}>{itemName(slot)}</div>
                    <div className="cc-muted" style={{ fontSize: 10 }}>
                      {(item?.fits || [])
                        .map((fit) => L.equipSlots[fit])
                        .filter(Boolean)
                        .join(', ') || L.handsOnly}
                    </div>
                  </div>
                </div>
              );
            })
          ) : (
            <div className="cc-hint">{L.allEquipped}</div>
          )}
        </div>
      </Frame>
    </div>
  );

  // ---- Stash page ----

  const renderStashPage = () => (
    <Frame className="ccl-pane">
      <div className="cc-hint">{L.stashHint}</div>
      <div className="cc-scroll" style={{ flex: 1, minHeight: 0 }}>
        <div className="ccl-items">
          {unequipped.map((slot) => {
            const item = byPath.get(slot.typepath || '');
            if (!item) {
              return null;
            }
            const inBag = bag.includes(String(slot.slot));
            return (
              <Tip
                key={slot.slot}
                className={`ccl-item ${inBag ? 'chosen' : ''}`}
                title={itemName(slot)}
                subtitle={inBag ? L.goesToBags : L.goesToStash}
                body={
                  <>
                    {itemTipBody(item, L, slot)}
                    <div className="ccl-tip-line cc-muted">
                      {L.bagToggleHint}
                    </div>
                  </>
                }
                onClick={() => act('bag', { slot: slot.slot })}
              >
                <span className="ccl-cost">
                  <Icon name={inBag ? 'shopping-bag' : 'archive'} />
                </span>
                {iconBox(item)}
                <div className="ccl-name">{itemName(slot)}</div>
              </Tip>
            );
          })}
        </div>
        {!unequipped.length ? (
          <div className="cc-hint">{L.allEquipped}</div>
        ) : null}
      </div>
    </Frame>
  );

  let body: ReactNode;
  if (page === 'equip') {
    body = renderEquipPage();
  } else if (page === 'stash') {
    body = renderStashPage();
  } else {
    body = renderItemsPage();
  }

  const presetLabel = (preset: Preset) =>
    `${preset.name || `${L.preset} ${preset.slot}`}${preset.role ? ` · ${preset.role}` : ''}${preset.empty ? ` (${L.empty})` : ''}`;

  return (
    <Window title={L.loadoutTitle} width={1180} height={780} theme="vanderlin">
      <Window.Content fitted>
        <style>{CSS + LOADOUT_CSS}</style>
        <div className="cc ccl">
          <div className="ccl-top cc-area-top" onMouseDown={startDrag}>
            <div className="ccl-title">{L.loadoutTitle}</div>
            {page === 'items' ? (
              <>
                <Select
                  value={category}
                  style={{ width: 170 }}
                  options={CATEGORIES.map((entry) => ({
                    value: entry,
                    label: L.loadoutCategories[entry],
                  }))}
                  onChange={setCategory}
                />
                <div className="cc-search">
                  <Icon className="cc-search-icon" name="search" />
                  <input
                    value={search}
                    placeholder={L.searchItems}
                    onChange={(event) => setSearch(event.target.value)}
                  />
                </div>
              </>
            ) : (
              <div className="cc-grow" />
            )}
            <div className="ccl-title">
              {points.spent} / {points.total} {L.points}
            </div>
            <Btn
              className="square danger"
              icon="times"
              title={L.close}
              onClick={() => suspendStart()}
            />
          </div>
          <div className="cc-area-content" style={{ minHeight: 0 }}>
            {body}
          </div>
          <Frame className="ccl-foot" style={{ gridArea: 'foot' }}>
            <Select
              value={String(presetSlot)}
              style={{ width: 260 }}
              options={presets.map((preset) => ({
                value: String(preset.slot),
                label: presetLabel(preset),
              }))}
              onChange={(value) => {
                setPresetSlot(Number(value));
                const preset = presets.find(
                  (entry) => entry.slot === Number(value),
                );
                if (preset && !preset.empty) {
                  loadoutAct('preset_load', { slot: Number(value) });
                }
              }}
            />
            {page === 'items' ? (
              <Select
                value={selectedPreset?.role || ''}
                placeholder={L.chooseRole}
                style={{ width: 200 }}
                options={[
                  { value: '', label: L.anyRole },
                  ...(data.roles || []).map((role) => ({
                    value: role,
                    label: role,
                  })),
                ]}
                onChange={(value) =>
                  act('preset_role', {
                    preset: presetSlot,
                    role: value || null,
                  })
                }
              />
            ) : null}
            <Btn
              icon="pen"
              disabled={!!selectedPreset?.empty}
              title={selectedPreset?.empty ? L.saveFirst : undefined}
              onClick={() => act('preset_rename', { preset: presetSlot })}
            >
              {L.rename}
            </Btn>
            <Btn
              icon="save"
              onClick={() => loadoutAct('preset_save', { slot: presetSlot })}
            >
              {L.save}
            </Btn>
            <Btn
              icon="undo"
              title={L.undoPresetHint}
              disabled={!!selectedPreset?.empty}
              onClick={() => loadoutAct('preset_load', { slot: presetSlot })}
            >
              {L.undo}
            </Btn>
            <Btn
              icon="trash"
              className="danger"
              title={L.clearAllHint}
              onClick={() => act('clear_all')}
            >
              {L.clear}
            </Btn>
            <div className="cc-grow" />
            {page !== 'items' ? (
              <Btn icon="arrow-left" onClick={() => setPage('items')}>
                {L.back}
              </Btn>
            ) : null}
            {page !== 'equip' ? (
              <Btn
                className="on"
                icon="tshirt"
                onClick={() => setPage('equip')}
              >
                {L.equipItems}
              </Btn>
            ) : null}
            {page !== 'stash' ? (
              <Btn
                className="on"
                icon="archive"
                onClick={() => setPage('stash')}
              >
                {L.checkStash}
              </Btn>
            ) : null}
          </Frame>
          <TipLayer pinHint={L.pinHint} />
        </div>
      </Window.Content>
    </Window>
  );
};

export default CharacterCreatorLoadout;

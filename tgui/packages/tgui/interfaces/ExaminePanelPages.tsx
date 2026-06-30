import { useEffect, useMemo, useRef, useState } from "react";
import { Box, Button, Image, Section, Stack } from "tgui-core/components";

import { resolveAsset } from "../assets";
import { useBackend } from "../backend";
import type {
  ExamineItem,
  ExaminePanelData,
  HeldItem,
  WornSlot,
} from "./ExaminePanelData";

const DESC_TRUNCATE_AT = 120;
const SLOT = 44; // slot box size in px
const BOTTOM_ROW_TOP = 310; // Y of the bottom corner+hands row inside the box
const ROW = 48; // vertical spacing between stacked slots

// Edge-anchored slot positions. Each slot hugs a real container edge (left/right
// + top/bottom) so the layout stays glued to the frame no matter the container's
// actual size (the byond map can report ~408px, not the nominal 360px).
type SlotPos = {
  left?: number;
  right?: number;
  top?: number;
  bottom?: number;
};
const SLOT_POS: Record<string, SlotPos> = {
  // Symmetric layout about the box's vertical center (axis = 180px of 360px).
  // Left and right columns each have 6 rows at identical Y positions; the right
  // column's top row holds mask (outer) + mouth (inner). Bottom corners mirror.
  // left column (outer left edge), top -> bottom
  head: { left: 6, top: 6 },
  shirt: { left: 6, top: 57 },
  gloves: { left: 6, top: 108 },
  belt: { left: 6, top: 158 },
  pants: { left: 6, top: 209 },
  shoes: { left: 6, top: 260 },
  // right column (outer right edge), top -> bottom; mouth shares the top row inward
  mask: { right: 6, top: 6 },
  mouth: { right: 54, top: 6 },
  armor: { right: 6, top: 57 },
  neck: { right: 6, top: 108 },
  cloak: { right: 6, top: 158 },
  ring: { right: 6, top: 209 },
  wrists: { right: 6, top: 260 },
  // bottom corners on the SAME verticals as the columns, mirrored about center
  // bottom-left: right shoulder (outer), right hip (inner)
  backr: { left: 6, top: 310 },
  beltr: { left: 54, top: 310 },
  // bottom-right: left hip (inner), left shoulder (outer)
  beltl: { right: 54, top: 310 },
  backl: { right: 6, top: 310 },
};

// Order the tooltip should open toward (away from the panel edge).
const TOOLTIP_SIDE: Record<string, "left" | "right"> = {
  head: "right",
  shirt: "right",
  gloves: "right",
  belt: "right",
  pants: "right",
  shoes: "right",
  backr: "right",
  beltr: "right",
  mouth: "left",
  mask: "left",
  armor: "left",
  neck: "left",
  cloak: "left",
  ring: "left",
  wrists: "left",
  beltl: "left",
  backl: "left",
};

// Frame colors keyed by the backend quality index (0..6); -1 = neutral default.
const QUALITY_COLORS: Record<number, string> = {
  [-1]: "#5a4632",
  0: "#6b6b6b",
  1: "#8a7a5a",
  2: "#b8b8b8",
  3: "#e8e0d0",
  4: "#5fa8d3",
  5: "#a96fd6",
  6: "#e0a93b",
};

const qualityColor = (q: number): string =>
  QUALITY_COLORS[q] ?? QUALITY_COLORS[-1];

// Diagonal hatch fill for empty / hidden slots.
const HATCH =
  "repeating-linear-gradient(45deg, rgba(90,70,50,0.35) 0px, rgba(90,70,50,0.35) 2px, transparent 2px, transparent 6px)";

const ItemTooltip = (props: {
  item: ExamineItem;
  label: string;
  side: "left" | "right";
  vAlign: "top" | "bottom";
  frameColor: string;
  onEnter: () => void;
  onLeave: () => void;
}) => {
  const { item, label, side, vAlign, frameColor, onEnter, onLeave } = props;
  const [expanded, setExpanded] = useState(false);
  const expandTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Only long descriptions get the truncate + delayed-expand behavior.
  const longDesc = item.desc.length > DESC_TRUNCATE_AT;

  useEffect(() => {
    if (!longDesc) {
      return;
    }
    // After 2s of hovering, expand to show the full text regardless of length.
    expandTimer.current = setTimeout(() => setExpanded(true), 2000);
    return () => {
      if (expandTimer.current) {
        clearTimeout(expandTimer.current);
      }
    };
  }, [longDesc]);

  const shownDesc =
    !longDesc || expanded
      ? item.desc
      : item.desc.slice(0, DESC_TRUNCATE_AT).trimEnd() + "...";

  return (
    <div
      onMouseEnter={onEnter}
      onMouseLeave={onLeave}
      style={{
        position: "absolute",
        // open toward panel center; bottom-row slots anchor their tooltip to
        // their own bottom edge so it grows upward and never clips past the box
        ...(vAlign === "top" ? { top: "0" } : { bottom: "0" }),
        [side === "right" ? "left" : "right"]: `${SLOT + 6}px`,
        zIndex: 30,
        width: expanded ? "248px" : "212px",
        maxHeight: "230px",
        overflowY: "auto",
        padding: "8px 10px",
        background: "#161009f8",
        border: `2px solid ${frameColor}`,
        borderRadius: "4px",
        boxShadow: "0 2px 10px rgba(0,0,0,0.85)",
        // pointer events ON so the user can scroll long descriptions
        pointerEvents: "auto",
        textAlign: "left",
      }}
    >
      <Box bold style={{ color: frameColor }} fontSize="13px">
        {item.name}
      </Box>
      <Box color="#8a7a66" fontSize="10px" italic mb={item.desc ? 0.5 : 0}>
        {label}
      </Box>
      {!!item.desc && (
        <Box
          color="#c7bba8"
          fontSize="11px"
          style={{ lineHeight: "1.4", whiteSpace: "pre-wrap" }}
        >
          {shownDesc}
        </Box>
      )}
    </div>
  );
};

const SimpleTooltip = (props: {
  title: string;
  subtitle: string;
  side: "left" | "right";
  vAlign: "top" | "bottom";
}) => {
  const { title, subtitle, side, vAlign } = props;
  return (
    <div
      style={{
        position: "absolute",
        ...(vAlign === "top" ? { top: "0" } : { bottom: "0" }),
        [side === "right" ? "left" : "right"]: `${SLOT + 6}px`,
        zIndex: 30,
        width: "140px",
        padding: "6px 9px",
        background: "#161009f8",
        border: "2px solid #5a4632",
        borderRadius: "4px",
        boxShadow: "0 2px 10px rgba(0,0,0,0.85)",
        pointerEvents: "none",
        textAlign: "left",
      }}
    >
      <Box bold style={{ color: "#9c8b73" }} fontSize="12px">
        {title}
      </Box>
      <Box color="#7a6a55" fontSize="10px" italic>
        {subtitle}
      </Box>
    </div>
  );
};

const GearSlot = (props: { slotId: string; slot: WornSlot }) => {
  const { slotId, slot } = props;
  const [hovered, setHovered] = useState(false);
  const closeTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pos = SLOT_POS[slotId];
  const side = TOOLTIP_SIDE[slotId] ?? "right";
  const filled = slot.status === "item" && slot.item;
  const frameColor = filled ? qualityColor(slot.item!.quality) : "#5a4632";
  // Only long descriptions need the hover bridge (cursor travels onto the
  // tooltip to scroll). Short/empty/hidden tooltips close instantly.
  const needsBridge = !!filled && slot.item!.desc.length > DESC_TRUNCATE_AT;
  // bottom corner slots open their tooltip upward
  const vAlign: "top" | "bottom" =
    slotId === "backr" ||
    slotId === "beltr" ||
    slotId === "beltl" ||
    slotId === "backl"
      ? "bottom"
      : "top";

  // Hover bridge: filled slots keep a short close delay so the cursor can travel
  // from the slot onto the tooltip to scroll a long description. Empty/hidden
  // slots have a non-interactive tooltip, so they close instantly - no lag.
  const open = () => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = null;
    }
    setHovered(true);
  };
  const scheduleClose = () => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = null;
    }
    // Only long-description tooltips keep a tiny bridge so the cursor can travel
    // onto them to scroll. Everything else (short item, empty, hidden) closes
    // the instant the cursor leaves the icon - no perceptible lag.
    if (!needsBridge) {
      setHovered(false);
      return;
    }
    closeTimer.current = setTimeout(() => setHovered(false), 120);
  };

  const posStyle: Record<string, string> = {};
  if (pos.left !== undefined) posStyle.left = `${pos.left}px`;
  if (pos.right !== undefined) posStyle.right = `${pos.right}px`;
  if (pos.top !== undefined) posStyle.top = `${pos.top}px`;
  if (pos.bottom !== undefined) posStyle.bottom = `${pos.bottom}px`;

  return (
    <div
      style={{
        position: "absolute",
        ...posStyle,
        zIndex: 2,
        width: `${SLOT}px`,
        height: `${SLOT}px`,
        border: `2px solid ${frameColor}`,
        borderRadius: "3px",
        background: filled ? "rgba(0,0,0,0.45)" : HATCH,
        boxShadow:
          filled && slot.item!.quality >= 4
            ? `0 0 5px ${frameColor}99`
            : "none",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: "help",
      }}
      onMouseEnter={() => open()}
      onMouseLeave={() => scheduleClose()}
    >
      {filled && slot.item!.icon ? (
        <img
          src={slot.item!.icon}
          style={{ width: "32px", height: "32px", imageRendering: "pixelated" }}
        />
      ) : null}
      {hovered && filled && (
        <ItemTooltip
          item={slot.item!}
          label={slot.label}
          side={side}
          vAlign={vAlign}
          frameColor={frameColor}
          onEnter={open}
          onLeave={scheduleClose}
        />
      )}
      {hovered && !filled && (
        <SimpleTooltip
          title={slot.label}
          subtitle={slot.status === "hidden" ? "Hidden" : "Empty"}
          side={side}
          vAlign={vAlign}
        />
      )}
    </div>
  );
};

const HandSlot = (props: { item?: HeldItem; label: string; left: number }) => {
  const { item, label, left } = props;
  const [hovered, setHovered] = useState(false);
  const closeTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const filled = !!item;
  const frameColor = filled ? qualityColor(item!.quality) : "#5a4632";
  const needsBridge = !!item && item.desc.length > DESC_TRUNCATE_AT;
  const open = () => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = null;
    }
    setHovered(true);
  };
  const scheduleClose = () => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = null;
    }
    if (!needsBridge) {
      setHovered(false);
      return;
    }
    closeTimer.current = setTimeout(() => setHovered(false), 120);
  };
  return (
    <div
      style={{
        position: "absolute",
        left: `${left}px`,
        top: `${BOTTOM_ROW_TOP}px`,
        zIndex: 2,
        width: `${SLOT}px`,
        height: `${SLOT}px`,
        border: `2px solid ${frameColor}`,
        borderRadius: "3px",
        background: filled ? "rgba(0,0,0,0.45)" : HATCH,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: filled ? "help" : "default",
      }}
      onMouseEnter={() => filled && open()}
      onMouseLeave={() => filled && scheduleClose()}
    >
      {filled && item!.icon ? (
        <img
          src={item!.icon}
          style={{ width: "32px", height: "32px", imageRendering: "pixelated" }}
        />
      ) : (
        <Box color="#5a4632" fontSize="9px">
          {label}
        </Box>
      )}
      {hovered && filled && (
        <ItemTooltip
          item={item!}
          label={item!.wielded ? "Wielded" : "In hand"}
          side="right"
          vAlign="bottom"
          frameColor={frameColor}
          onEnter={open}
          onLeave={scheduleClose}
        />
      )}
    </div>
  );
};

const CharacterPortrait = (props: { nsfw: boolean }) => {
  const { act, data } = useBackend<ExaminePanelData>();
  const {
    headshot,
    nsfw_headshot,
    has_headshot,
    has_nsfw_headshot,
    preview_image,
    worn_items,
  } = data;
  const hasShot = props.nsfw ? has_nsfw_headshot : has_headshot;
  const shot = props.nsfw
    ? nsfw_headshot || "headshot_red.png"
    : headshot || "headshot_red.png";
  // Default to the live character preview when no headshot is set
  const [showPreview, setShowPreview] = useState(!hasShot);
  const previewActive = showPreview || !hasShot;

  // Ask the server to flatten the character the first time the preview is shown
  useEffect(() => {
    if (previewActive && !preview_image) {
      act("generate_preview");
    }
  }, [previewActive, preview_image]);

  return (
    <Stack vertical g={0.5}>
      <Stack.Item>
        <div
          style={{
            position: "relative",
            width: "360px",
            height: "360px",
            flexShrink: 0,
            margin: "0 auto",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          {previewActive &&
            worn_items?.slots &&
            Object.keys(SLOT_POS).map((slotId) => {
              const slot = worn_items.slots[slotId];
              if (!slot) {
                return null;
              }
              return <GearSlot key={slotId} slotId={slotId} slot={slot} />;
            })}
          {previewActive && (
            <>
              <HandSlot
                item={worn_items?.hands?.[1] ?? undefined}
                label="R"
                left={132}
              />
              <HandSlot
                item={worn_items?.hands?.[0] ?? undefined}
                label="L"
                left={184}
              />
            </>
          )}
          {previewActive ? (
            preview_image ? (
              <img
                src={preview_image}
                style={{
                  // 1.5x size (360px) to fill the empty space between the doll
                  // and the edge slots. Absolutely centered and behind the slots
                  // (zIndex 0) so its transparent margins sit under them without
                  // covering or blocking the slot frames/tooltips.
                  position: "absolute",
                  top: "50%",
                  left: "50%",
                  transform: "translate(-50%, -50%)",
                  zIndex: 0,
                  width: "360px",
                  height: "360px",
                  imageRendering: "pixelated",
                  pointerEvents: "none",
                }}
              />
            ) : (
              <Box color="gray" italic>
                Loading character...
              </Box>
            )
          ) : (
            <img
              src={resolveAsset(shot)}
              width="320px"
              height="320px"
              style={{ objectFit: "contain" }}
            />
          )}
        </div>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" justify="center">
          {previewActive && (
            <Stack.Item>
              <Button
                icon="rotate-left"
                tooltip="Rotate counterclockwise"
                onClick={() => act("rotate", { clockwise: false })}
              />
            </Stack.Item>
          )}
          <Stack.Item>
            <Button
              icon={previewActive ? "image" : "user"}
              disabled={!hasShot}
              tooltip={
                hasShot
                  ? previewActive
                    ? "Show the headshot image"
                    : "Show the in-game character"
                  : "No headshot set"
              }
              onClick={() => setShowPreview(!previewActive)}
            >
              {previewActive ? "Headshot" : "Character Preview"}
            </Button>
          </Stack.Item>
          {previewActive && (
            <Stack.Item>
              <Button
                icon="rotate-right"
                tooltip="Rotate clockwise"
                onClick={() => act("rotate", { clockwise: true })}
              />
            </Stack.Item>
          )}
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

export const FlavorTextPage = (props) => {
  const { data } = useBackend<ExaminePanelData>();
  const { flavor_text, flavor_text_nsfw, ooc_notes, ooc_notes_nsfw, is_naked } =
    data;
  const [oocNotesIndex, setOocNotesIndex] = useState("SFW");
  const [flavorTextIndex, setFlavorTextIndex] = useState("SFW");

  const flavorHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${flavor_text}</span>`,
    }),
    [flavor_text],
  );

  const nsfwHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${flavor_text_nsfw}</span>`,
    }),
    [flavor_text_nsfw],
  );

  const oocHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${ooc_notes}</span>`,
    }),
    [ooc_notes],
  );

  const oocnsfwHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${ooc_notes_nsfw}</span>`,
    }),
    [ooc_notes_nsfw],
  );

  return (
    <Stack fill>
      <div style={{ width: "372px", flexShrink: 0, flexGrow: 0 }}>
        <Stack fill vertical>
          <Stack.Item align="center">
            <CharacterPortrait nsfw={flavorTextIndex === "NSFW"} />
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item grow width="300px">
                <Section
                  scrollable
                  fill
                  title="OOC Notes"
                  preserveWhitespace
                  buttons={
                    <>
                      <Button
                        selected={oocNotesIndex === "SFW"}
                        bold={oocNotesIndex === "SFW"}
                        onClick={() => {
                          setOocNotesIndex("SFW");
                        }}
                        textAlign="center"
                        minWidth="60px"
                      >
                        SFW
                      </Button>
                      <Button
                        selected={oocNotesIndex === "NSFW"}
                        disabled={!ooc_notes_nsfw}
                        bold={oocNotesIndex === "NSFW"}
                        onClick={() => {
                          setOocNotesIndex("NSFW");
                        }}
                        textAlign="center"
                        minWidth="60px"
                      >
                        NSFW
                      </Button>
                    </>
                  }
                >
                  {oocNotesIndex === "SFW" && (
                    <Box
                      dangerouslySetInnerHTML={{
                        __html: ooc_notes
                          ? `<span class='Chat'>${ooc_notes}</span>`
                          : "<i>No OOC notes provided.</i>",
                      }}
                    />
                  )}
                  {oocNotesIndex === "NSFW" && (
                    <Box dangerouslySetInnerHTML={oocnsfwHTML} />
                  )}
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </div>
      <Stack.Item grow>
        <Section
          scrollable
          fill
          preserveWhitespace
          title="Flavor Text"
          buttons={
            <>
              <Button
                selected={flavorTextIndex === "SFW"}
                bold={flavorTextIndex === "SFW"}
                onClick={() => setFlavorTextIndex("SFW")}
                textAlign="center"
                width="60px"
              >
                SFW
              </Button>
              <Button
                selected={flavorTextIndex === "NSFW"}
                disabled={!is_naked || !flavor_text_nsfw}
                bold={flavorTextIndex === "NSFW"}
                onClick={() => setFlavorTextIndex("NSFW")}
                textAlign="center"
                width="60px"
              >
                NSFW
              </Button>
            </>
          }
        >
          {flavorTextIndex === "SFW" && (
            <Box
              dangerouslySetInnerHTML={{
                __html: flavor_text
                  ? `<span class='Chat'>${flavor_text}</span>`
                  : "<i>No flavor text provided.</i>",
              }}
            />
          )}
          {flavorTextIndex === "NSFW" && (
            <Box dangerouslySetInnerHTML={nsfwHTML} />
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export const ImageGalleryPage = () => {
  const { data } = useBackend<ExaminePanelData>();
  const { img_gallery, nsfw_img_gallery, is_naked } = data;
  const imgGallery = Array.isArray(img_gallery) ? img_gallery : [];
  const nsfwImgGallery = Array.isArray(nsfw_img_gallery)
    ? nsfw_img_gallery
    : [];

  const [galleryMode, setGalleryMode] = useState<"SFW" | "NSFW">("SFW");

  const images = galleryMode === "NSFW" ? nsfwImgGallery : imgGallery;

  return (
    <Section
      title="Image Gallery"
      fill
      scrollable
      buttons={
        <>
          <Button
            selected={galleryMode === "SFW"}
            bold={galleryMode === "SFW"}
            onClick={() => setGalleryMode("SFW")}
            textAlign="center"
            minWidth="60px"
          >
            SFW
          </Button>
          <Button
            selected={galleryMode === "NSFW"}
            disabled={!is_naked || nsfwImgGallery.length === 0}
            bold={galleryMode === "NSFW"}
            onClick={() => setGalleryMode("NSFW")}
            textAlign="center"
            minWidth="60px"
          >
            NSFW
          </Button>
        </>
      }
    >
      {images.length === 0 ? (
        <Box align="center" color="gray">
          No images available.
        </Box>
      ) : (
        <Stack fill justify="space-evenly">
          {images.map((val) => (
            <Stack.Item grow key={val}>
              <Section align="center">
                <Image
                  maxHeight="100%"
                  maxWidth="100%"
                  src={resolveAsset(val)}
                />
              </Section>
            </Stack.Item>
          ))}
        </Stack>
      )}
    </Section>
  );
};

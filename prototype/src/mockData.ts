export type ContextType = "text" | "code" | "url" | "image" | "file" | "thought";

export type ContextItem = {
  id: string;
  type: ContextType;
  title: string;
  preview: string;
  source: string;
  age: string;
  accent: string;
  detail: string;
};

export const categories: Array<{ id: "all" | ContextType; label: string }> = [
  { id: "all", label: "All" },
  { id: "code", label: "Code" },
  { id: "image", label: "Visuals" },
  { id: "url", label: "Links" },
  { id: "file", label: "Files" },
  { id: "thought", label: "Thoughts" },
  { id: "text", label: "Text" }
];

export const intents = [
  "Debug this",
  "Implement this",
  "Review this",
  "Explain this",
  "Turn into task",
  "Create goal"
];

export const contextItems: ContextItem[] = [
  {
    id: "ctx-clip-error",
    type: "text",
    title: "Renderer crash note",
    preview: "Panel flickers when the gallery repaints after selection. Looks tied to root size mutation.",
    source: "Clipboard",
    age: "2m",
    accent: "#8bc7b2",
    detail: "Captured from issue triage"
  },
  {
    id: "ctx-code-position",
    type: "code",
    title: "Positioning branch",
    preview: "if (origin.x + width > frame.maxX) { origin.x = anchor.x - width - gap }",
    source: "Editor",
    age: "6m",
    accent: "#d6b879",
    detail: "Swift sketch"
  },
  {
    id: "ctx-url-gsap",
    type: "url",
    title: "GSAP timeline docs",
    preview: "Timeline defaults, labels, and position parameter notes for staged panel motion.",
    source: "Browser",
    age: "11m",
    accent: "#87a9d9",
    detail: "gsap.com"
  },
  {
    id: "ctx-image-surface",
    type: "image",
    title: "Dark surface reference",
    preview: "A cropped command surface with search, category pills, and media-heavy context cards.",
    source: "Screenshot",
    age: "18m",
    accent: "#c99595",
    detail: "1280 x 742"
  },
  {
    id: "ctx-file-prd",
    type: "file",
    title: "Handy PRD",
    preview: "/Users/justin/workspace/handy/docs/prd.md",
    source: "Finder",
    age: "24m",
    accent: "#a6b889",
    detail: "Markdown"
  },
  {
    id: "ctx-thought-slogan",
    type: "thought",
    title: "Attention promise",
    preview: "Handy should feel summoned into the current task, not launched as another destination.",
    source: "Quick thought",
    age: "31m",
    accent: "#b8a2d1",
    detail: "Product note"
  }
];

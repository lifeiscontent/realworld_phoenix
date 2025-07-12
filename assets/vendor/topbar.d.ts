interface TopbarConfig {
  barColors?: {
    [key: string]: string;
  };
  shadowColor?: string;
  className?: string;
}

interface Topbar {
  config(options: TopbarConfig): void;
  show(delayMs?: number): void;
  hide(): void;
  progress(value: number | string): void;
}

declare const topbar: Topbar;
export default topbar;
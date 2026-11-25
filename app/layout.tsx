import type { Metadata, Viewport } from 'next';
import './globals.css';
export const metadata: Metadata = {title:'SyncTogether — Find your time together',description:'A calm, private way to see when your people are free.',manifest:'/manifest.webmanifest',appleWebApp:{capable:true,statusBarStyle:'default',title:'SyncTogether'}};
export const viewport: Viewport = {themeColor:'#f7f6fb',width:'device-width',initialScale:1};
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="es"><body>{children}<script dangerouslySetInnerHTML={{__html:`if ('serviceWorker' in navigator) window.addEventListener('load',()=>navigator.serviceWorker.register('/sw.js').catch(console.error));`}} /></body></html>; }

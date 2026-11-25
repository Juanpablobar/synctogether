import type {MetadataRoute} from 'next';
export default function manifest():MetadataRoute.Manifest{return {name:'SyncTogether',short_name:'SyncTogether',description:'Find your time together',start_url:'/',display:'standalone',background_color:'#f7f6fb',theme_color:'#f7f6fb',icons:[{src:'/icon.svg',sizes:'any',type:'image/svg+xml',purpose:'any'}]};}

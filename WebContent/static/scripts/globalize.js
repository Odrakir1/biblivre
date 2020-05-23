/*!
 * Globalize
 *
 * http://github.com/jquery/globalize
 *
 * Copyright Software Freedom Conservancy, Inc.
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 */
!function(e,r){var t,n,a,s,u,l,i,c,o,f,d,p,h,g,b,y,m,M,v,k,z,F,A,x,S,I,w,C,D,H,O,N;t=function(e){return new t.prototype.init(e)},"undefined"!=typeof require&&"undefined"!=typeof exports&&"undefined"!=typeof module?module.exports=t:e.Globalize=t,t.cultures={},t.prototype={constructor:t,init:function(e){return this.cultures=t.cultures,this.cultureSelector=e,this}},t.prototype.init.prototype=t.prototype,t.cultures.default={name:"en",englishName:"English",nativeName:"English",isRTL:!1,language:"en",numberFormat:{pattern:["-n"],decimals:2,",":",",".":".",groupSizes:[3],"+":"+","-":"-",NaN:"NaN",negativeInfinity:"-Infinity",positiveInfinity:"Infinity",percent:{pattern:["-n %","n %"],decimals:2,groupSizes:[3],",":",",".":".",symbol:"%"},currency:{pattern:["($n)","$n"],decimals:2,groupSizes:[3],",":",",".":".",symbol:"$"}},calendars:{standard:{name:"Gregorian_USEnglish","/":"/",":":":",firstDay:0,days:{names:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],namesAbbr:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],namesShort:["Su","Mo","Tu","We","Th","Fr","Sa"]},months:{names:["January","February","March","April","May","June","July","August","September","October","November","December",""],namesAbbr:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec",""]},AM:["AM","am","AM"],PM:["PM","pm","PM"],eras:[{name:"A.D.",start:null,offset:0}],twoDigitYearMax:2029,patterns:{d:"M/d/yyyy",D:"dddd, MMMM dd, yyyy",t:"h:mm tt",T:"h:mm:ss tt",f:"dddd, MMMM dd, yyyy h:mm tt",F:"dddd, MMMM dd, yyyy h:mm:ss tt",M:"MMMM dd",Y:"yyyy MMMM",S:"yyyy'-'MM'-'dd'T'HH':'mm':'ss"}}},messages:{}},t.cultures.default.calendar=t.cultures.default.calendars.standard,t.cultures.en=t.cultures.default,t.cultureSelector="en",n=/^0x[a-f0-9]+$/i,a=/^[+\-]?infinity$/i,s=/^[+\-]?\d*\.?\d*(e[+\-]?\d+)?$/,u=/^\s+|\s+$/g,l=function(e,r){if(e.indexOf)return e.indexOf(r);for(var t=0,n=e.length;t<n;t++)if(e[t]===r)return t;return-1},i=function(e,r){return e.substr(e.length-r.length)===r},c=function(){var e,r,t,n,a,s,u=arguments[0]||{},l=1,i=arguments.length,p=!1;for("boolean"==typeof u&&(p=u,u=arguments[1]||{},l=2),"object"==typeof u||f(u)||(u={});l<i;l++)if(null!=(e=arguments[l]))for(r in e)t=u[r],u!==(n=e[r])&&(p&&n&&(d(n)||(a=o(n)))?(a?(a=!1,s=t&&o(t)?t:[]):s=t&&d(t)?t:{},u[r]=c(p,s,n)):void 0!==n&&(u[r]=n));return u},o=Array.isArray||function(e){return"[object Array]"===Object.prototype.toString.call(e)},f=function(e){return"[object Function]"===Object.prototype.toString.call(e)},d=function(e){return"[object Object]"===Object.prototype.toString.call(e)},p=function(e,r){return 0===e.indexOf(r)},h=function(e){return(e+"").replace(u,"")},g=function(e){return isNaN(e)?NaN:Math[e<0?"ceil":"floor"](e)},b=function(e,r,t){var n;for(n=e.length;n<r;n+=1)e=t?"0"+e:e+"0";return e},y=function(e,r){for(var t=0,n=!1,a=0,s=e.length;a<s;a++){var u=e.charAt(a);switch(u){case"'":n?r.push("'"):t++,n=!1;break;case"\\":n&&r.push("\\"),n=!n;break;default:r.push(u),n=!1}}return t},m=function(e,r){r=r||"F";var t,n=e.patterns,a=r.length;if(1===a){if(!(t=n[r]))throw"Invalid date format string '"+r+"'.";r=t}else 2===a&&"%"===r.charAt(0)&&(r=r.charAt(1));return r},M=function(e,r,t){var n,a=t.calendar,s=a.convert;if(!r||!r.length||"i"===r){if(t&&t.name.length)if(s)n=M(e,a.patterns.F,t);else{var u=new Date(e.getTime()),l=z(e,a.eras);u.setFullYear(F(e,a,l)),n=u.toLocaleString()}else n=e.toString();return n}var i=a.eras,c="s"===r;r=m(a,r),n=[];var o,f,d,p,h=["0","00","000"],g=/([^d]|^)(d|dd)([^d]|$)/g,b=0,v=k();function A(e,r){var t,n=e+"";return r>1&&n.length<r?(t=h[r-2]+n).substr(t.length-r,r):t=n}function x(e,r){if(p)return p[r];switch(r){case 0:return e.getFullYear();case 1:return e.getMonth();case 2:return e.getDate();default:throw"Invalid part value "+r}}for(!c&&s&&(p=s.fromGregorian(e));;){var S=v.lastIndex,I=v.exec(r),w=r.slice(S,I?I.index:r.length);if(b+=y(w,n),!I)break;if(b%2)n.push(I[0]);else{var C=I[0],D=C.length;switch(C){case"ddd":case"dddd":var H=3===D?a.days.namesAbbr:a.days.names;n.push(H[e.getDay()]);break;case"d":case"dd":f=!0,n.push(A(x(e,2),D));break;case"MMM":case"MMMM":var O=x(e,1);n.push(a.monthsGenitive&&(f||d?f:(f=g.test(r),d=!0,f))?a.monthsGenitive[3===D?"namesAbbr":"names"][O]:a.months[3===D?"namesAbbr":"names"][O]);break;case"M":case"MM":n.push(A(x(e,1)+1,D));break;case"y":case"yy":case"yyyy":O=p?p[0]:F(e,a,z(e,i),c),D<4&&(O%=100),n.push(A(O,D));break;case"h":case"hh":0===(o=e.getHours()%12)&&(o=12),n.push(A(o,D));break;case"H":case"HH":n.push(A(e.getHours(),D));break;case"m":case"mm":n.push(A(e.getMinutes(),D));break;case"s":case"ss":n.push(A(e.getSeconds(),D));break;case"t":case"tt":O=e.getHours()<12?a.AM?a.AM[0]:" ":a.PM?a.PM[0]:" ",n.push(1===D?O.charAt(0):O);break;case"f":case"ff":case"fff":n.push(A(e.getMilliseconds(),3).substr(0,D));break;case"z":case"zz":o=e.getTimezoneOffset()/60,n.push((o<=0?"+":"-")+A(Math.floor(Math.abs(o)),D));break;case"zzz":o=e.getTimezoneOffset()/60,n.push((o<=0?"+":"-")+A(Math.floor(Math.abs(o)),2)+":"+A(Math.abs(e.getTimezoneOffset()%60),2));break;case"g":case"gg":a.eras&&n.push(a.eras[z(e,i)].name);break;case"/":n.push(a["/"]);break;default:throw"Invalid date format pattern '"+C+"'."}}}return n.join("")},S=function(e,r,t){var n=t.groupSizes,a=n[0],s=1,u=Math.pow(10,r),l=Math.round(e*u)/u;isFinite(l)||(l=e);var i=(e=l)+"",c="",o=i.split(/e/i),f=o.length>1?parseInt(o[1],10):0;o=(i=o[0]).split("."),i=o[0],c=o.length>1?o[1]:"",f>0?(i+=(c=b(c,f,!1)).slice(0,f),c=c.substr(f)):f<0&&(c=(i=b(i,1+(f=-f),!0)).slice(-f,i.length)+c,i=i.slice(0,-f)),c=r>0?t["."]+(c.length>r?c.slice(0,r):b(c,r)):"";for(var d=i.length-1,p=t[","],h="";d>=0;){if(0===a||a>d)return i.slice(0,d+1)+(h.length?p+h+c:c);h=i.slice(d-a+1,d+1)+(h.length?p+h:""),d-=a,s<n.length&&(a=n[s],s++)}return i.slice(0,d+1)+p+h+c},v=function(e,r,t){if(!isFinite(e))return e===1/0?t.numberFormat.positiveInfinity:e===-1/0?t.numberFormat.negativeInfinity:t.numberFormat.NaN;if(!r||"i"===r)return t.name.length?e.toLocaleString():e.toString();r=r||"D";var n,a=t.numberFormat,s=Math.abs(e),u=-1;r.length>1&&(u=parseInt(r.slice(1),10));var l,i=r.charAt(0).toUpperCase();switch(i){case"D":n="n",s=g(s),-1!==u&&(s=b(""+s,u,!0)),e<0&&(s="-"+s);break;case"N":l=a;case"C":l=l||a.currency;case"P":l=l||a.percent,n=e<0?l.pattern[0]:l.pattern[1]||"n",-1===u&&(u=l.decimals),s=S(s*("P"===i?100:1),u,l);break;default:throw"Bad number format specifier: "+i}for(var c=/n|\$|-|%/g,o="";;){var f=c.lastIndex,d=c.exec(n);if(o+=n.slice(f,d?d.index:n.length),!d)break;switch(d[0]){case"n":o+=s;break;case"$":o+=a.currency.symbol;break;case"-":/[1-9]/.test(s)&&(o+=a["-"]);break;case"%":o+=a.percent.symbol}}return o},k=function(){return/\/|dddd|ddd|dd|d|MMMM|MMM|MM|M|yyyy|yy|y|hh|h|HH|H|mm|m|ss|s|tt|t|fff|ff|f|zzz|zz|z|gg|g/g},z=function(e,r){if(!r)return 0;for(var t,n=e.getTime(),a=0,s=r.length;a<s;a++)if(null===(t=r[a].start)||n>=t)return a;return 0},F=function(e,r,t,n){var a=e.getFullYear();return!n&&r.eras&&(a-=r.eras[t].offset),a},I=function(e,r){if(r<100){var t=new Date,n=z(t),a=F(t,e,n),s=e.twoDigitYearMax;(r+=a-a%100)>(s="string"==typeof s?(new Date).getFullYear()%100+parseInt(s,10):s)&&(r-=100)}return r},w=function(e,r,t){var n,a=e.days,s=e._upperDays;return s||(e._upperDays=s=[N(a.names),N(a.namesAbbr),N(a.namesShort)]),r=O(r),t?-1===(n=l(s[1],r))&&(n=l(s[2],r)):n=l(s[0],r),n},C=function(e,r,t){var n=e.months,a=e.monthsGenitive||e.months,s=e._upperMonths,u=e._upperMonthsGen;s||(e._upperMonths=s=[N(n.names),N(n.namesAbbr)],e._upperMonthsGen=u=[N(a.names),N(a.namesAbbr)]),r=O(r);var i=l(t?s[1]:s[0],r);return i<0&&(i=l(t?u[1]:u[0],r)),i},D=function(e,r){var t=e._parseRegExp;if(t){var n=t[r];if(n)return n}else e._parseRegExp=t={};for(var a,s=m(e,r).replace(/([\^\$\.\*\+\?\|\[\]\(\)\{\}])/g,"\\\\$1"),u=["^"],l=[],i=0,c=0,o=k();null!==(a=o.exec(s));){var f=s.slice(i,a.index);if(i=o.lastIndex,(c+=y(f,u))%2)u.push(a[0]);else{var d,p=a[0],h=p.length;switch(p){case"dddd":case"ddd":case"MMMM":case"MMM":case"gg":case"g":d="(\\D+)";break;case"tt":case"t":d="(\\D*)";break;case"yyyy":case"fff":case"ff":case"f":d="(\\d{"+h+"})";break;case"dd":case"d":case"MM":case"M":case"yy":case"y":case"HH":case"H":case"hh":case"h":case"mm":case"m":case"ss":case"s":d="(\\d\\d?)";break;case"zzz":d="([+-]?\\d\\d?:\\d{2})";break;case"zz":case"z":d="([+-]?\\d\\d?)";break;case"/":d="(\\/)";break;default:throw"Invalid date format pattern '"+p+"'."}d&&u.push(d),l.push(a[0])}}y(s.slice(i),u),u.push("$");var g={regExp:u.join("").replace(/\s+/g,"\\s+"),groups:l};return t[r]=g},H=function(e,r,t){return e<r||e>t},O=function(e){return e.split(" ").join(" ").toUpperCase()},N=function(e){for(var r=[],t=0,n=e.length;t<n;t++)r[t]=O(e[t]);return r},A=function(e,r,t){e=h(e);var n=t.calendar,a=D(n,r),s=new RegExp(a.regExp).exec(e);if(null===s)return null;for(var u,l=a.groups,i=null,c=null,o=null,f=null,d=null,g=0,b=0,y=0,m=0,M=null,v=!1,k=0,z=l.length;k<z;k++){var F=s[k+1];if(F){var A=l[k],x=A.length,S=parseInt(F,10);switch(A){case"dd":case"d":if(H(f=S,1,31))return null;break;case"MMM":case"MMMM":if(o=C(n,F,3===x),H(o,0,11))return null;break;case"M":case"MM":if(H(o=S-1,0,11))return null;break;case"y":case"yy":case"yyyy":if(c=x<4?I(n,S):S,H(c,0,9999))return null;break;case"h":case"hh":if(12===(g=S)&&(g=0),H(g,0,11))return null;break;case"H":case"HH":if(H(g=S,0,23))return null;break;case"m":case"mm":if(H(b=S,0,59))return null;break;case"s":case"ss":if(H(y=S,0,59))return null;break;case"tt":case"t":if(!(v=n.PM&&(F===n.PM[0]||F===n.PM[1]||F===n.PM[2]))&&(!n.AM||F!==n.AM[0]&&F!==n.AM[1]&&F!==n.AM[2]))return null;break;case"f":case"ff":case"fff":if(m=S*Math.pow(10,3-x),H(m,0,999))return null;break;case"ddd":case"dddd":if(d=w(n,F,3===x),H(d,0,6))return null;break;case"zzz":var O=F.split(/:/);if(2!==O.length)return null;if(u=parseInt(O[0],10),H(u,-12,13))return null;var N=parseInt(O[1],10);if(H(N,0,59))return null;M=60*u+(p(F,"-")?-N:N);break;case"z":case"zz":if(H(u=S,-12,13))return null;M=60*u;break;case"g":case"gg":var T=F;if(!T||!n.eras)return null;T=h(T.toLowerCase());for(var j=0,$=n.eras.length;j<$;j++)if(T===n.eras[j].name.toLowerCase()){i=j;break}if(null===i)return null}}}var P,G=new Date,E=n.convert;if(P=E?E.fromGregorian(G)[0]:G.getFullYear(),null===c?c=P:n.eras&&(c+=n.eras[i||0].offset),null===o&&(o=0),null===f&&(f=1),E){if(null===(G=E.toGregorian(c,o,f)))return null}else{if(G.setFullYear(c,o,f),G.getDate()!==f)return null;if(null!==d&&G.getDay()!==d)return null}if(v&&g<12&&(g+=12),G.setHours(g,b,y,m),null!==M){var Y=G.getMinutes()-(M+G.getTimezoneOffset());G.setHours(G.getHours()+parseInt(Y/60,10),Y%60)}return G},x=function(e,r,t){var n,a=r["-"],s=r["+"];switch(t){case"n -":a=" "+a,s=" "+s;case"n-":i(e,a)?n=["-",e.substr(0,e.length-a.length)]:i(e,s)&&(n=["+",e.substr(0,e.length-s.length)]);break;case"- n":a+=" ",s+=" ";case"-n":p(e,a)?n=["-",e.substr(a.length)]:p(e,s)&&(n=["+",e.substr(s.length)]);break;case"(n)":p(e,"(")&&i(e,")")&&(n=["-",e.substr(1,e.length-2)])}return n||["",e]},t.prototype.findClosestCulture=function(e){return t.findClosestCulture.call(this,e)},t.prototype.format=function(e,r,n){return t.format.call(this,e,r,n)},t.prototype.localize=function(e,r){return t.localize.call(this,e,r)},t.prototype.parseInt=function(e,r,n){return t.parseInt.call(this,e,r,n)},t.prototype.parseFloat=function(e,r,n){return t.parseFloat.call(this,e,r,n)},t.prototype.culture=function(e){return t.culture.call(this,e)},t.addCultureInfo=function(e,r,t){var n={},a=!1;"string"!=typeof e?(t=e,e=this.culture().name,n=this.cultures[e]):"string"!=typeof r?(t=r,a=null==this.cultures[e],n=this.cultures[e]||this.cultures.default):(a=!0,n=this.cultures[r]),this.cultures[e]=c(!0,{},n,t),a&&(this.cultures[e].calendar=this.cultures[e].calendars.standard)},t.findClosestCulture=function(e){var r;if(!e)return this.findClosestCulture(this.cultureSelector)||this.cultures.default;if("string"==typeof e&&(e=e.split(",")),o(e)){var t,n,a=this.cultures,s=e,u=s.length,l=[];for(n=0;n<u;n++){var i,c=(e=h(s[n])).split(";");t=h(c[0]),1===c.length?i=1:0===(e=h(c[1])).indexOf("q=")?(e=e.substr(2),i=parseFloat(e),i=isNaN(i)?0:i):i=1,l.push({lang:t,pri:i})}for(l.sort(function(e,r){return e.pri<r.pri?1:e.pri>r.pri?-1:0}),n=0;n<u;n++)if(r=a[t=l[n].lang])return r;for(n=0;n<u;n++)for(t=l[n].lang;;){var f=t.lastIndexOf("-");if(-1===f)break;if(r=a[t=t.substr(0,f)])return r}for(n=0;n<u;n++)for(var d in t=l[n].lang,a){var p=a[d];if(p.language==t)return p}}else if("object"==typeof e)return e;return r||null},t.format=function(e,r,t){var n=this.findClosestCulture(t);return e instanceof Date?e=M(e,r,n):"number"==typeof e&&(e=v(e,r,n)),e},t.localize=function(e,r){return this.findClosestCulture(r).messages[e]||this.cultures.default.messages[e]},t.parseDate=function(e,r,t){var n,a,s;if(t=this.findClosestCulture(t),r){if("string"==typeof r&&(r=[r]),r.length)for(var u=0,l=r.length;u<l;u++){var i=r[u];if(i&&(n=A(e,i,t)))break}}else for(a in s=t.calendar.patterns)if(n=A(e,s[a],t))break;return n||null},t.parseInt=function(e,r,n){return g(t.parseFloat(e,r,n))},t.parseFloat=function(e,r,t){"number"!=typeof r&&(t=r,r=10);var u=this.findClosestCulture(t),l=NaN,i=u.numberFormat;if(e.indexOf(u.numberFormat.currency.symbol)>-1&&(e=(e=e.replace(u.numberFormat.currency.symbol,"")).replace(u.numberFormat.currency["."],u.numberFormat["."])),e.indexOf(u.numberFormat.percent.symbol)>-1&&(e=e.replace(u.numberFormat.percent.symbol,"")),e=e.replace(/ /g,""),a.test(e))l=parseFloat(e);else if(!r&&n.test(e))l=parseInt(e,16);else{var c=x(e,i,i.pattern[0]),o=c[0],f=c[1];""===o&&"(n)"!==i.pattern[0]&&(o=(c=x(e,i,"(n)"))[0],f=c[1]),""===o&&"-n"!==i.pattern[0]&&(o=(c=x(e,i,"-n"))[0],f=c[1]),o=o||"+";var d,p,h=f.indexOf("e");h<0&&(h=f.indexOf("E")),h<0?(p=f,d=null):(p=f.substr(0,h),d=f.substr(h+1));var g,b,y=i["."],m=p.indexOf(y);m<0?(g=p,b=null):(g=p.substr(0,m),b=p.substr(m+y.length));var M=i[","];g=g.split(M).join("");var v=M.replace(/\u00A0/g," ");M!==v&&(g=g.split(v).join(""));var k=o+g;if(null!==b&&(k+="."+b),null!==d){var z=x(d,i,"-n");k+="e"+(z[0]||"+")+z[1]}s.test(k)&&(l=parseFloat(k))}return l},t.culture=function(e){return void 0!==e&&(this.cultureSelector=e),this.findClosestCulture(e)||this.cultures.default}}(this);
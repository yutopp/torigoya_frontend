/// <reference path="base64_utf8.ts"/>

module ProcGarden {
    export function b64_to_utf8(str: string) {
        try {
            return UTF8ArrToStr(base64DecToArr(str));
        } catch(e) {
            return window.atob(str);
        }
    }

    export function dc(num: number): string {
        return num.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1,');
    }

    export function mem_dc(num: number): string {
        return dc(num/1024);
    }
}
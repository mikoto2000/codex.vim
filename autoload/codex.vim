" codex
" Version: 0.0.1
" Author: mikoto2000
" License: MIT

if exists('g:loaded_codex')
  finish
endif
let g:loaded_codex = 1

let s:save_cpo = &cpo
set cpo&vim

packadd vital.vim
let s:HTTP = vital#vital#import("Web.HTTP")

let s:ENDPOINT_URL = "https://api.openai.com/v1/responses"
let s:HEADERS = {
      \  "Content-Type": "application/json",
      \  "Authorization": "Bearer " . $OPENAI_API_KEY
      \}
let s:MODEL = "gpt-5"

let s:prev_response_id = ''

function! codex#OpenCodexBuffer() abort
    """ 呼び出し元のウィンドウ ID を記憶
    let s:caller_window_id = win_getid()

    """ 新しいバッファを作成
    silent bo new __CODEX_BUFFER__

    """ バッファリスト用バッファの設定
    setlocal noshowcmd
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nonumber
endfunction

function! codex#AppendText(text) abort
  " 追記する行データを用意（文字列 or リストの両対応）
  let lines = type(a:text) == v:t_list ? a:text : split(a:text, "\n", 1)

  " codex 用バッファの特定（なければ作成）
  let name = '__CODEX_BUFFER__'
  let buf  = bufnr(name)
  if buf == -1
    call codex#OpenCodexBuffer()
    let buf  = bufnr(name)
  endif

  if !bufloaded(buf) | call bufload(buf) | endif


  " 末尾に追記（空バッファなら1行目を置換）
  let lc = getbufinfo(buf)[0].linecount
  if lc == 1 && getbufline(buf, 1)[0] ==# ''
    call setbufline(buf, 1, lines)
  else
    call appendbufline(buf, lc, lines)
  endif
endfunction

function! codex#ExitCb(job, code, headers, body) abort
  let body_text = type(a:body) == v:t_list ? join(a:body, "\n") : a:body
  let body_json = json_decode(body_text)
  let text = body_json.output[1].content[0].text
  call codex#AppendText(text)

  " stateful 用に id を保持（あれば更新）
  if has_key(body_json, 'id') && type(body_json.id) == v:t_string && !empty(body_json.id)
    let s:prev_response_id = body_json.id
  endif
endfunction

function! codex#Request(text) abort
  let payload = {
        \   "model": s:MODEL,
        \   "input": a:text
        \ }

  if type(s:prev_response_id) == v:t_string && !empty(s:prev_response_id)
    let payload.previous_response_id = s:prev_response_id
  endif

  call s:HTTP.request_async({
        \ "url": s:ENDPOINT_URL,
        \ "method": "POST",
        \ "headers": s:HEADERS,
        \ "data": json_encode(payload),
        \ "exit_cb": "codex#ExitCb"
        \})
endfunction

function! codex#ResetContext() abort
  let s:prev_response_id = ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

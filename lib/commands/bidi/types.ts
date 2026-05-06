export interface NativeVideoChunkAddedEvent extends BiDiEvent<NativeVideoChunkAddedParams> {}

interface BiDiEvent<TParams> {
  method: string;
  params: TParams;
}

interface NativeVideoChunkAddedParams {
  uuid: string;
  payload: string;
}

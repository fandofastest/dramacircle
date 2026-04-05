import axios from "axios";
import { env } from "./env";

export const externalApiClient = axios.create({
  baseURL: env.EXTERNAL_API_BASE_URL,
  timeout: 15000
});

import * as YAML from 'yaml';
import specsYaml from '../specs.yaml';
import type { Specs, CommandSpec, OperationSpec, Argument } from '../types.js';

let cachedSpecs: Specs | null = null;

const specsSource = specsYaml as unknown;

function parseSpecs(): Specs {
  if (typeof specsSource === 'string') {
    return YAML.parse(specsSource, { schema: 'core' }) as Specs;
  }
  return specsSource as Specs;
}

export function loadSpecs(): Specs {
  if (!cachedSpecs) {
    cachedSpecs = parseSpecs();
  }
  return cachedSpecs!;
}

export function getCommandSpec(
  commandName: string,
  operationName?: string
): OperationSpec | CommandSpec | null {
  const specs = loadSpecs();
  const command = specs.commands.find(
    (cmd: CommandSpec) => cmd.name === commandName
  );

  if (!command) {
    return null;
  }

  if (operationName && command.operations) {
    return (
      command.operations.find(
        (op: OperationSpec) => op.name === operationName
      ) || null
    );
  }

  return command;
}

export function getArgumentSpec(
  commandName: string,
  argumentName: string,
  operationName?: string
): Argument | null {
  const spec = getCommandSpec(commandName, operationName);

  if (!spec || !spec.arguments) {
    return null;
  }

  return (
    spec.arguments.find((arg: Argument) => arg.name === argumentName) || null
  );
}

export function buildPromptChoices(argument: Argument) {
  if (!argument.options) {
    return null;
  }

  // Handle simple string array options
  if (
    Array.isArray(argument.options) &&
    typeof argument.options[0] === 'string'
  ) {
    return (argument.options as string[]).map((option) => ({
      name: option,
      message: option.charAt(0).toUpperCase() + option.slice(1),
      value: option,
    }));
  }

  // Handle complex option objects with name, value, and description
  if (
    Array.isArray(argument.options) &&
    typeof argument.options[0] === 'object'
  ) {
    return (
      argument.options as Array<{
        name: string;
        value: string;
        description?: string;
      }>
    ).map((option) => ({
      name: option.value,
      message: option.description
        ? `${option.name} - ${option.description}`
        : option.name,
      value: option.value,
    }));
  }

  return null;
}

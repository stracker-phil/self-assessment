/**
 USAGE
 -----

 Create a webpack.config.js in the project root directory, with the
 content structure below.
 Note, that the last entry should be `...sharedScripts()`


 ````
 # file: webpack.config.js

 import {script} from './bin/lib/webpack.shared';

 export default [
	 script('loader'),
	 script('front'),
	 script('post-editor'),
	 script('post-list'),
	 script('builder'),
	 script('preview'),
	 script('settings'),
	 ...sharedScripts()
 ];

 ````
 */

const path = require('path');
const WebpackAssetsManifest = require('webpack-assets-manifest');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require('terser-webpack-plugin');

const PROD = 'production' === process.env.NODE_ENV;

function toCamelCase(str) {
	return str.split(/[_-]/).map(word => {
		return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
	}).join('');
}


function script(name, asLibrary = false, isLocal = true) {
	const dirName = isLocal ? '/' : '/shared/';

	// Path to the library root directory, relative to the entryDir.
	const rootDir = '../..' + dirName;

	// Path to the source files that should be processed by webpack.
	const entryDir = rootDir + 'sources/scripts/';

	const absScriptsDir = path.resolve(__dirname, rootDir, 'scripts/');
	const absEntryDir = path.resolve(__dirname, entryDir);
	const outputConfig = {};

	if (asLibrary) {
		/**
		 * A library exposes all exported members in a global object.
		 *
		 * Samples:
		 *   - name:    lib
		 *   - library: DivimodeLib
		 *
		 *   - name:    visual-builder
		 *   - library: DivimodeVisualBuilder
		 *
		 * Consume the library methods:
		 *
		 * <script src="/path/to/lib.js"></script>
		 * <script>window.DivimodeLib.exposedMethod();</script>
		 */
		outputConfig.library = {
			name: 'Divimode' + toCamelCase(name),
			type: 'window',
		};

		outputConfig.filename = '[name].bundle.min.js';
	} else {
		outputConfig.filename = '[name].min.js';
	}

	return {
		name: 'divimode_' + name.replace(/-/g, '_'),

		entry: {
			[name]: path.resolve(__dirname, entryDir + name + '.js'),
		},

		output: {
			...outputConfig,

			globalObject: 'window',
			path: absScriptsDir,
		},

		resolve: {
			extensions: [
				'.ts', '.tsx', '.js', '.jsx', '.d.ts'
			],
			modules: [
				absEntryDir, 'node_modules',
			],
		},

		externals: {},

		optimization: {
			minimize: PROD,
			minimizer: [new TerserPlugin()],
			concatenateModules: true,

			/*
			 * deterministic:
			 * Short numeric ids which will not be changing between compilation. Good for long term caching.
			 */
			chunkIds: PROD ? 'deterministic' : 'named',
			moduleIds: PROD ? 'deterministic' : 'named',
			flagIncludedChunks: PROD,
			removeAvailableModules: PROD,
			mangleExports: PROD ? 'deterministic' : false,

			splitChunks: {
				chunks: 'all',
				minSize: 20000, // Minimum size, in bytes, for a chunk to be generated.
				maxSize: 50000, // Maximum size for the created chunks

				name: 'chunk/' + name,
			},
		},

		module: {
			rules: [
				{
					test: /\.m?js$/,
					exclude: /node_modules/,
					use: {
						loader: 'babel-loader',
						options: {
							presets: ['@babel/preset-env'],
						},
					},
				}, {
					test: /\.tsx?$/,
					use: 'ts-loader',
					exclude: [/node_modules/, /\.d\.ts$/],
				}, {
					test: /\.s?css$/,
					use: [
						{
							loader: MiniCssExtractPlugin.loader,
							options: {
								publicPath: '../',
							},
						}, {
							loader: 'css-loader',
							options: {
								url: false,
							},
						}, {
							loader: 'postcss-loader',
							options: {
								postcssOptions: {
									plugins: [
										require('postcss-url')({
											url: asset => asset.url.replace('../../', '../'),
										}),
									],
								},
							},
						}, 'sass-loader',
					],
				},
			],
		},

		plugins: [
			new WebpackAssetsManifest({
				output: name + '.json',
				sortManifest: false,
				publicPath: dirName + 'scripts/', // the type-prefix is removed by the customize callback.
				writeToDisk: true,
				customize(entry) {
					return {
						key: entry.key,
						value: entry.value.replace(new RegExp(`^${dirName.replace(/\//g, '\\\/')}`), ''),
					};
				},
			}), new MiniCssExtractPlugin({
				filename: `../styles/[name].min.css`,
			}),
		],
	};
}


function sharedScript(name) {
	return script(name, false, false);
}


function sharedScripts() {
	return [
		sharedScript('lib'), sharedScript('dashboard'), sharedScript('rich-text-editor'), sharedScript('admin'),
	];
}


module.exports = {
	script,
	sharedScripts,
};

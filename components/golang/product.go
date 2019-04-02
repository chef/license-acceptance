package main

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	toml "github.com/BurntSushi/toml"
)

type Product struct {
	Name       string
	PrettyName string `toml:"pretty_name"`
	HabPkgID   string `toml:"hab_pkg_id"`
	Filename   string
}

type ProductSet []Product

type Relationships map[string]([]string)

type ProductInfo struct {
	Products       ProductSet
	Relationships  Relationships
	ProductByHabID map[string]Product
	ProductByName  map[string]Product
}

func ReadProductInfo() *ProductInfo {
	location, set := os.LookupEnv("CHEF_LICENSE_PRODUCT_INFO")
	if set == false {
		location = "../../product_info.toml"
	}

	var info ProductInfo
	if _, err := toml.DecodeFile(location, &info); err != nil {
		fmt.Println("Could not read product information")
		os.Exit(172)
	}
	info.ProductByHabID = make(map[string]Product, 0)
	info.ProductByName = make(map[string]Product, 0)
	for _, product := range info.Products {
		if product.HabPkgID == "" {
			continue
		}
		info.ProductByHabID[product.HabPkgID] = product
		info.ProductByName[product.Name] = product
	}
	return &info
}

func (info *ProductInfo) RequiredProductLicenses(habPkgID string) []Product {
	required := make([]Product, 0)
	firstProduct, ok := info.ProductByHabID[habPkgID]
	if !ok {
		fmt.Printf("Missing product with Hab ID %s in product_info.toml\n", habPkgID)
		os.Exit(172)
	}
	required = append(required, firstProduct)
	childrenNames, ok := info.Relationships[firstProduct.Name]
	if ok {
		for _, childName := range childrenNames {
			child, ok := info.ProductByName[childName]
			if !ok {
				fmt.Printf("Defined relationship from %s to %s in product_info.toml but child does not exist\n", firstProduct.Name, childName)
				os.Exit(172)
			}
			required = append(required, child)
		}
	}
	return required
}

func HasAcceptedLicense(config Configuration, product Product) bool {
	searchPaths := config.ReadPaths
	for _, path := range searchPaths {
		if _, err := os.Stat(filepath.Join(path, product.Filename)); err == nil {
			return true
		}
	}
	return false
}

// AttemptPersistLicense - Attempt to persist the license marker file for the
// given product. Does not fail if the file cannot be written.
func AttemptPersistLicense(config Configuration, product Product, t time.Time, acceptingProductName string, acceptingProductVersion string, username string) int {
	err := os.MkdirAll(config.PersistPath, 0755)
	if err != nil {
		return 0
	}

	path := filepath.Join(config.PersistPath, product.Filename)
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0644)
	if err != nil {
		return 0
	}

	formattedTime := t.Format(time.RFC3339)
	out := "---\n" +
		"name: %s\n" +
		"date_accepted: '%s'\n" +
		"accepting_product: %s\n" +
		"accepting_product_version: %s\n" +
		"user: %s\n" +
		"file_format: 1"
	out = fmt.Sprintf(out, product.Name, formattedTime, acceptingProductName, acceptingProductVersion, username)

	n, err := f.Write([]byte(out))
	if n > 0 && err == nil {
		return 1
	}
	return 0
}
